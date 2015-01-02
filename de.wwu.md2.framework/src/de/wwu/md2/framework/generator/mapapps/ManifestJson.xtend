package de.wwu.md2.framework.generator.mapapps

import de.wwu.md2.framework.generator.preprocessor.ProcessController
import de.wwu.md2.framework.generator.util.DataContainer
import de.wwu.md2.framework.mD2.AlternativesPane
import de.wwu.md2.framework.mD2.BooleanInput
import de.wwu.md2.framework.mD2.Button
import de.wwu.md2.framework.mD2.ContainerElement
import de.wwu.md2.framework.mD2.ContentElement
import de.wwu.md2.framework.mD2.DateInput
import de.wwu.md2.framework.mD2.DateTimeInput
import de.wwu.md2.framework.mD2.EntitySelector
import de.wwu.md2.framework.mD2.GridLayoutPane
import de.wwu.md2.framework.mD2.GridLayoutPaneColumnsParam
import de.wwu.md2.framework.mD2.HexColorDef
import de.wwu.md2.framework.mD2.Image
import de.wwu.md2.framework.mD2.IntegerInput
import de.wwu.md2.framework.mD2.Label
import de.wwu.md2.framework.mD2.NumberInput
import de.wwu.md2.framework.mD2.OptionInput
import de.wwu.md2.framework.mD2.Spacer
import de.wwu.md2.framework.mD2.StyleAssignment
import de.wwu.md2.framework.mD2.StyleDefinition
import de.wwu.md2.framework.mD2.TabbedAlternativesPane
import de.wwu.md2.framework.mD2.TextInput
import de.wwu.md2.framework.mD2.TimeInput
import de.wwu.md2.framework.mD2.Tooltip
import de.wwu.md2.framework.mD2.ViewGUIElement
import de.wwu.md2.framework.mD2.WidthParam
import de.wwu.md2.framework.mD2.WorkflowElement
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.xbase.lib.Pair

import static extension de.wwu.md2.framework.generator.mapapps.util.MD2MapappsUtil.*
import static extension de.wwu.md2.framework.generator.util.MD2GeneratorUtil.*
import static extension de.wwu.md2.framework.util.StringExtensions.*
import de.wwu.md2.framework.mD2.WorkflowElementReference

class ManifestJson {
		
	def static String generateManifestJsonForModels(DataContainer dataContainer, ResourceSet processedInput) {
		var appName = dataContainer.workflows?.head.apps?.head.appName
		'''
			{
			    «generateBundlePropertiesSnippet(dataContainer, "model")»
			    "Require-Bundle": [
			        {
			            "name": "md2_runtime"
			        }
			    ],
			    "Components": [
					«val snippets = newArrayList(
						generateModelsSnippet(dataContainer, processedInput)
					)»
					«FOR snippet : snippets.filter(s | !s.toString.trim.empty) SEPARATOR ","»
						«snippet»
					«ENDFOR»
			    ]
			}
		'''
	}
	def static String generateManifestJsonForContentProviders(DataContainer dataContainer, ResourceSet processedInput) {
		var appName = dataContainer.workflows?.head.apps?.head.appName
		'''
			{
				«generateBundlePropertiesSnippet(dataContainer, "content_provider")»
				"Require-Bundle": [
					«IF dataContainer.contentProviders.exists[it.local]»
						{
							"name": "md2_local_store"
						},
					«ENDIF»
					«IF dataContainer.contentProviders.exists[it.connection != null || it.^default]»
						{
							"name": "md2_store"
						},
					«ENDIF»
					{
						"name": "md2_runtime"
					}
				],
				"Components": [
					«val snippets = newArrayList(
						generateContentProvidersSnippet(dataContainer, processedInput)
					)»
					«FOR snippet : snippets.filter(s | !s.toString.trim.empty) SEPARATOR ","»
						«snippet»
					«ENDFOR»
				]
			}
		'''
	}
	
	/**
	 * Generates manifest.json code for WorkflowElements.
	 */
	def static String generateManifestJsonForWorkflowElement(WorkflowElement workflowElement, DataContainer dataContainer, ResourceSet processedInput) {
		var appName = dataContainer.workflows?.head.apps?.head.appName
		'''
			{
				"Bundle-SymbolicName": "«workflowElement.bundleName»", //TODO:"md2_wfe_«processedInput.getBasePackageName.split("\\.").reduce[ s1, s2 | s1 + "_" + s2]»"
				"Bundle-Version": "«dataContainer.main.appVersion»",
				"Bundle-Name": "Workflow element «workflowElement.name»",
				"Bundle-Description": "Generated MD2 workflow element bundle: «workflowElement.name» of «appName»",
				"Bundle-Localization": [],
				"Bundle-Main": "",
			    "Require-Bundle": [
			        {
			            "name": "md2_runtime"
			        },
			        {
			            "name": "md2_models"
			        },
			        {
			            "name": "md2_content_providers"
			        },
					{
						"name": "md2_workflow"
					}
				],
				"Components": [
					«val snippets = newArrayList(
						generateConfigurationSnippet(workflowElement, dataContainer, processedInput),
						generateCustomActionsSnippet(workflowElement, dataContainer, processedInput),
						generateControllerSnippet(workflowElement, dataContainer, processedInput),
						generateToolSnippet(workflowElement, dataContainer, processedInput)
					)»
					«FOR snippet : snippets.filter(s | !s.toString.trim.empty) SEPARATOR ","»
						«snippet»
					«ENDFOR»
				]
			}
		'''
	}
	
	def static String generateManifestJsonForWorkflowHandler(DataContainer dataContainer, ResourceSet processedInput) {
		var appName = dataContainer.workflows?.head.apps?.head.appName;
		'''
			{
				«generateBundlePropertiesSnippet(dataContainer, "workflow")»
			    "Require-Bundle": [
			        {
			            "name": "md2_runtime"
			        }
			    ],
			    "Components": [
			        {
			            "name": "WorkflowEventHandler",
			            "provides": ["md2.workflow.EventHandler"],
			            "instanceFactory": true,
			            "immediate": true,
			            "references": [
			                {
			                    "name": "controller",
			                    "providing": "md2.app.«appName».controllers",
			                    "policy": "dynamic",
			                    "cardinality": "0..n"
			                }
			            ]
			        }
			    ]
			}
		'''
	}
	
	
	def private static generateBundlePropertiesSnippet(DataContainer dataContainer, String type){
	var appName = dataContainer.workflows?.head.apps?.head.appName;
				
	'''«IF (type=="workflow")»
		"Bundle-SymbolicName": "md2_workflow",
		"Bundle-Name": "«appName» «type»",
		"Bundle-Description": "Generated MD2 bundle: «type» of «appName»",
		«ELSE»
		"Bundle-SymbolicName": "md2_«type»s",
		"Bundle-Name": "«appName» «type»s",
		"Bundle-Description": "Generated MD2 bundle: «type»s of «appName»",
		«ENDIF»"Bundle-Version": "2.0",
"Bundle-Localization": [],
"Bundle-Main": "",'''
		
	}
	
	def private static String generateConfigurationSnippet(WorkflowElement workflowElement, DataContainer dataContainer, ResourceSet processedInput) {
	    var appName = dataContainer.workflows?.head.apps?.head.appName;
		'''
			{
				"name": "MD2«workflowElement.name»",//TODO: processedInput.getBasePackageName.split("\\.").last.toFirstUpper
				"impl": "ct/Stateful",
				"provides": ["md2.wfe.«workflowElement.name».AppDefinition"], //TODO: «processedInput.getBasePackageName»
				"propertiesConstructor": true,
				"properties": {
				    "appId": "md2_«appName»",
					"id": "md2_«workflowElement.name.replace(".", "_")»", //TODO: processedInput.getBasePackageName.replace(".", "_")
					"windowTitle": "«workflowElement»",
					"onInitialized": "«ProcessController::startupActionName»",
					"views": [
						«FOR view : dataContainer.rootViewContainers.get(workflowElement) SEPARATOR ","»
							{
								"name": "«view.name»",
								"dataForm": {
									"dataform-version": "1.0.0",
									«getViewElement(view, processedInput, false)»
								}
							}
						«ENDFOR»
					]
				}
			}
		'''
	}
	
	def static generateCustomActionsSnippet(WorkflowElement workflowElement, DataContainer dataContainer, ResourceSet processedInput) '''
		{
			"name": "CustomActions",
			"provides": ["md2.wfe.«workflowElement.name».CustomActions"], //TODO: processedInput.getBasePackageName
			"instanceFactory": true
		}
	'''
	
	def static generateModelsSnippet(DataContainer dataContainer, ResourceSet processedInput) '''
		{
			"name": "Models",
			"provides": ["md2.app.«dataContainer.workflows?.head.apps?.head.appName».Models"],
			"instanceFactory": true
		}
	'''
	
	def static generateContentProvidersSnippet(DataContainer dataContainer, ResourceSet processedInput) {
		var uri = dataContainer.workflows?.head.apps?.head?.defaultConnection?.uri
		'''
			«FOR contentProvider : dataContainer.contentProviders SEPARATOR ","»
				{
					"name": "«contentProvider.name.toFirstUpper»Provider",
					"impl": "./contentproviders/«contentProvider.name.toFirstUpper»",
					"provides": ["md2.app.«dataContainer.workflows?.head.apps?.head.appName».ContentProvider"],
					«IF !contentProvider.local»
						"propertiesConstructor": true,
						"properties": {
							"uri": "«IF contentProvider.^default»«uri»«ELSE»«contentProvider.connection.uri»«ENDIF»"
						},
					«ENDIF»
					"references": [
						{
							«IF contentProvider.local»
								"name": "_localFactory",
								"providing": "md2.store.LocalStore",
							«ELSE»
								"name": "_remoteFactory",
								"providing": "md2.store.RemoteStore",
							«ENDIF»
							"cardinality": "0..1"
						}
					]
				}
			«ENDFOR»
		'''
	}
	
	def static generateControllerSnippet(WorkflowElement workflowElement, DataContainer dataContainer, ResourceSet processedInput) 
	{
	var appName = dataContainer.workflows?.head.apps?.head.appName;
	'''
		{
			"name": "Controller",
			"provides": ["md2.wfe.«workflowElement.name».Controller","md2.app.«appName».controllers"], //TODO: processedInput.getBasePackageName
			"instanceFactory": true,
			"references": [
				{
					"name": "_md2AppWidget",
					"providing": "md2.runtime.InstanceFactory"
				},
				{
					"name": "_customActions",
					"providing": "md2.wfe.«workflowElement.name».CustomActions"
				},
				{
					"name": "_models",
					"providing": "md2.app.«appName».Models"
				},
				{
					"name": "_contentProviders",
					"providing": "md2.app.«appName».ContentProvider",
					"cardinality": "0..n"
				},
				{
					"name": "_configBean",
					"providing": "md2.wfe.«workflowElement.name».AppDefinition"
				},
				{
					"name": "_workflowEventHandler",
					"providing": "md2.workflow.EventHandler"
				}
			]
		}
	'''
	}
	
	/**
	 * Generates a "Tool" code snippet for every "startable" WorkflowElement.
	 * The title of the mapapps tool within the application is set to its startable
	 * alias.
	 */
	def static generateToolSnippet(WorkflowElement workflowElement, DataContainer dataContainer, ResourceSet processedInput) {
		val wfeReferences = processedInput.allContents.filter(typeof (WorkflowElementReference)).toList.filter(wfe | wfe.startable == true)
		val startableWFE = wfeReferences.filter(wfe | wfe.workflowElementReference.name == workflowElement.name).toList
		var startableAlias = ""
		var isStartable = false
		if (startableWFE.size == 1){
			isStartable = true
			startableAlias = startableWFE.get(0).alias
		}
		
		'''
		«IF isStartable»
			{
				"name": "MD2«workflowElement.name.split("\\.").last.toFirstUpper»Tool", //TODO: processedInput.getBasePackageName
				"impl": "ct.tools.Tool",
				"provides": ["ct.tools.Tool"],
				"propertiesConstructor": true,
				"properties": {
					"id": "md2_wfe_«workflowElement.name.replace(".", "_")»_tool",
					"title": "«startableAlias»",
					"description": "Start «workflowElement.name»", //TODO: Insert good description
					"tooltip": "«startableAlias»", //TODO: Insert good tooltip
					"toolRole": "toolset",
					"iconClass": "icon-view-grid",
					"togglable": true,
					"activateHandler": "openWindow",
					"deactivateHandler": "closeWindow"
				},
				"references": [
					{
						"name": "handlerScope",
						"providing": "md2.wfe.«workflowElement.name».Controller"
					}
				]
			}
		«ENDIF»
		'''
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////
	// Dispatch: All ViewGUIElements
	////////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * TODO If there is a warning "Cannot infer type from recursive usage. Type 'Object' is used.", this is related to
	 *      Eclipse Bug 404817 (https://bugs.eclipse.org/bugs/show_bug.cgi?id=404817).
	 *      This todo can be removed when the bug is fixed! Until then the return type String has to be specified
	 *      explicitly.
	 */
	 
	
	/***************************************************************
	 * Container Elements
	 ***************************************************************/
	
	def private static dispatch String getViewElement(GridLayoutPane gridLayout, ResourceSet processedInput, boolean isSubView) '''
		"type": "md2gridpanel",
		"cols": "«gridLayout.params.filter(typeof(GridLayoutPaneColumnsParam)).head.value»",
		"valueClass": "layoutCell",
		«generateStyle(null, "width" -> '''«gridLayout.params.filter(typeof(WidthParam)).head.width»%''')»,
		«IF isSubView»"subViewName": "«getName(gridLayout)»",«ENDIF»
		"children": [
			«FOR element : gridLayout.elements.filter(typeof(ViewGUIElement)) SEPARATOR ","»
				{
					«switch element {
						ContentElement: getViewElement(element, processedInput)
						ContainerElement: getViewElement(element, processedInput, false)
					}»
				}
			«ENDFOR»
		]
	'''
	
	def private static dispatch String getViewElement(TabbedAlternativesPane tabbedPane, ResourceSet processedInput, boolean isSubView) '''
		"type": "tabpanel",
		"valueClass": "layoutCell",
		«generateStyle(null, "width" -> '''100%''')»,
		«IF isSubView»"subViewName": "«getName(tabbedPane)»",«ENDIF»
		"children": [
			«FOR element : tabbedPane.elements.filter(typeof(ContainerElement)) SEPARATOR ","»
				{
					"title": "«element.tabName»",
					«getViewElement(element, processedInput, true)»
				}
			«ENDFOR»
		]
	'''
	
	def private static dispatch String getViewElement(AlternativesPane alternativesPane, ResourceSet processedInput, boolean isSubView) '''
		"type": "stackcontainer",
		"valueClass": "layoutCell",
		«generateStyle(null, "width" -> '''«alternativesPane.params.filter(typeof(WidthParam)).head.width»%''')»,
		«IF isSubView»"subViewName": "«getName(alternativesPane)»",«ENDIF»
		"children": [
			«FOR element : alternativesPane.elements.filter(typeof(ContainerElement)) SEPARATOR ","»
				{
					«getViewElement(element, processedInput, true)»
				}
			«ENDFOR»
		]
	'''
	
	
	/***************************************************************
	 * Content Elements => Various
	 ***************************************************************/
	 
	def private static dispatch String getViewElement(Image image, ResourceSet processedInput) '''
		"type": "simpleimage",
		"src": "md2_app_«processedInput.getBasePackageName.split("\\.").reduce[ s1, s2 | s1 + "_" + s2]»:./resources/«image.src»",
		«IF image.imgWidth > 0»"imgW": «image.imgWidth»,«ENDIF»
		«IF image.imgHeight > 0»"imgH": «image.imgHeight»,«ENDIF»
		«generateStyle(null, "width" -> '''«image.width»%''')»
	'''
	
	def private static dispatch String getViewElement(Spacer spacer, ResourceSet processedInput) '''
		"type": "spacer",
		«generateStyle(null, "width" -> '''«spacer.width»%''')»
	'''
	
	def private static dispatch String getViewElement(Button button, ResourceSet processedInput) '''
		"type": "button",
		"title": "«button.text.escape»",
		"field": "«getName(button)»",
		«generateStyle(button.style, "width" -> '''«button.width»%''')»
	'''
	
	def private static dispatch String getViewElement(Label label, ResourceSet processedInput) '''
		"type": "textoutput",
		"datatype": "string",
		"field": "«getName(label)»",
		"defaultText": "«label.text.escape»",
		«generateStyle(label.style, "width" -> '''«label.width»%''')»
	'''
	
	def private static dispatch String getViewElement(Tooltip tooltip, ResourceSet processedInput) '''
		"type": "tooltipicon",
		"datatype": "string",
		"field": "«getName(tooltip)»",
		"defaultText": "«tooltip.text.escape»",
		«generateStyle(null, "width" -> '''«tooltip.width»%''')»
	'''
	
	
	/***************************************************************
	 * Content Elements => Input
	 ***************************************************************/
	
	def private static dispatch String getViewElement(BooleanInput input, ResourceSet processedInput) '''
		"type": "checkbox",
		"datatype": "boolean",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(TextInput input, ResourceSet processedInput) '''
		"type": "textbox",
		"datatype": "string",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(IntegerInput input, ResourceSet processedInput) '''
		"type": "numberspinner",
		"datatype": "integer",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(NumberInput input, ResourceSet processedInput) '''
		"type": "numbertextbox",
		"datatype": "float",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(DateInput input, ResourceSet processedInput) '''
		"type": "datetextbox",
		"datatype": "date",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(TimeInput input, ResourceSet processedInput) '''
		"type": "timetextbox",
		"datatype": "time",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(DateTimeInput input, ResourceSet processedInput) '''
		"type": "datetimebox",
		"datatype": "datetime",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(OptionInput input, ResourceSet processedInput) '''
		"type": "selectbox",
		"datatype": "«input.enumReference.name.toFirstUpper»",
		"field": "«getName(input)»",
		«generateStyle(null, "width" -> '''«input.width»%''')»
	'''
	
	def private static dispatch String getViewElement(EntitySelector input, ResourceSet processedInput) '''
		// TODO
	'''
	
	
	////////////////////////////////////////////////////////////////////////////////////////////
	// Generate Styles
	////////////////////////////////////////////////////////////////////////////////////////////
	
	def private static generateStyle(StyleAssignment styleAssignment, Pair<String, String>... additionalValues) {
		
		val values = newArrayList(additionalValues)
		
		// all style references were replaced by the actual definitions during pre-processing
		val style = (styleAssignment as StyleDefinition)?.definition
		
		if (style != null && style.bold) {
			values.add("font-weight" -> "bold")
		}
		
		if (style != null && style.italic) {
			values.add("font-style" -> "italic")
		}
		
		if (style?.color != null) {
			// after pre-processing all colors are in hex format
			values.add("color" -> (style.color as HexColorDef).color)
		}
		
		if (style != null && style.fontSize != 0d) {
			values.add("font-size" -> '''«style.fontSize»em''')
		}
		
		'''
			"cellStyle": {
				«FOR value : values SEPARATOR ","»
					"«value.key»": "«value.value»"
				«ENDFOR»
			}
		'''
	}
	
}