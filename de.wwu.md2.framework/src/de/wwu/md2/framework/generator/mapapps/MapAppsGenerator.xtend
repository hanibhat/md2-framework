package de.wwu.md2.framework.generator.mapapps

import de.wwu.md2.framework.generator.AbstractPlatformGenerator
import de.wwu.md2.framework.generator.IExtendedFileSystemAccess
import de.wwu.md2.framework.mD2.WorkflowElement
import de.wwu.md2.framework.mD2.CustomAction

import static de.wwu.md2.framework.generator.mapapps.AppClass.*
import static de.wwu.md2.framework.generator.mapapps.ContentProviderClass.*
import static de.wwu.md2.framework.generator.mapapps.ControllerClass.*
import static de.wwu.md2.framework.generator.mapapps.CustomActionClass.*
import static de.wwu.md2.framework.generator.mapapps.CustomActionsInterfaceClass.*
import static de.wwu.md2.framework.generator.mapapps.EntityClass.*
import static de.wwu.md2.framework.generator.mapapps.EnumClass.*
import static de.wwu.md2.framework.generator.mapapps.EventHandlerClass.*
import static de.wwu.md2.framework.generator.mapapps.ManifestJson.*
import static de.wwu.md2.framework.generator.mapapps.ModelsInterfaceClass.*
import static de.wwu.md2.framework.generator.mapapps.ModuleClass.*

import static extension de.wwu.md2.framework.generator.util.MD2GeneratorUtil.*
import static extension de.wwu.md2.framework.util.StringExtensions.*
import static extension de.wwu.md2.framework.generator.mapapps.util.MD2MapappsUtil.*

class MapAppsGenerator extends AbstractPlatformGenerator {
	
	override doGenerate(IExtendedFileSystemAccess fsa) {
		
		/////////////////////////////////////////
		// Generation work flow
		/////////////////////////////////////////
		
		var bundlesRootFolder = rootFolder + "/bundles"
		
		fsa.generateFile(rootFolder + "/app.json", generateAppJson(dataContainer).tabsToSpaces(4))
		
		fsa.generateFile(bundlesRootFolder + "/bundles.json", generateBundleJson(dataContainer).tabsToSpaces(4))
		
		// for each bundle generate
		for(WorkflowElement workflowElement : dataContainer.controllers.head.controllerElements.filter(WorkflowElement)) {
			var bundleFolder = bundlesRootFolder + "/" + workflowElement.bundleName 
			
			generateWorkflowElementBundle(fsa, bundleFolder, workflowElement)
		}
		
		generateModelsBundle(fsa, bundlesRootFolder + "/md2_models")
		generateContentProvidersBundle(fsa, bundlesRootFolder + "/md2_contentproviders")
		generateWorkflowBundle(fsa, bundlesRootFolder + "/md2_workflows")
		
		/////////////////////////////////////////
		// Build zip file for bundle
		/////////////////////////////////////////
		
		val zipFileName = '''md2_app_«processedInput.getBasePackageName.split("\\.").reduce[ s1, s2 | s1 + "_" + s2]».zip'''
		fsa.zipDirectory(rootFolder, rootFolder + "/../" + zipFileName);
		
	}
	
	def generateWorkflowElementBundle(IExtendedFileSystemAccess fsa, String bundleFolder, WorkflowElement workflowElement) {
		fsa.generateFile(bundleFolder + "/module.js", generateModuleForWorkflowElement().tabsToSpaces(4))
		
		fsa.generateFile(bundleFolder + "/manifest.json", generateManifestJsonForWorkflowElement(workflowElement, dataContainer, processedInput).tabsToSpaces(4))
		
		fsa.generateFile(bundleFolder + "/Controller.js", generateController(dataContainer).tabsToSpaces(4))
		
		fsa.generateFile(bundleFolder + "/CustomActions.js", generateCustomActionsInterface(dataContainer).tabsToSpaces(4))
		
		for (customAction : workflowElement.actions.filter(CustomAction)) {
			fsa.generateFile(bundleFolder + "/actions/" + customAction.name.toFirstUpper + ".js", generateCustomAction(customAction).tabsToSpaces(4))
		}
	}
	
	def generateModelsBundle(IExtendedFileSystemAccess fsa, String modelBundleFolder){
		fsa.generateFile(modelBundleFolder + "/module.js", generateModuleForModels().tabsToSpaces(4))
		
		fsa.generateFile(modelBundleFolder + "/manifest.json", generateManifestJsonForModels(dataContainer, processedInput).tabsToSpaces(4))
		
		fsa.generateFile(modelBundleFolder + "/Models.js", generateModelsInterface(dataContainer).tabsToSpaces(4))
		
		for (entity : dataContainer.entities) {
			fsa.generateFile(modelBundleFolder + "/models/" + entity.name.toFirstUpper + ".js", generateEntity(entity).tabsToSpaces(4))
		}
		
		for (^enum : dataContainer.enums) {
			fsa.generateFile(modelBundleFolder + "/models/" + enum.name.toFirstUpper + ".js", generateEnum(enum).tabsToSpaces(4))
		}	
	}
	
	def generateWorkflowBundle(IExtendedFileSystemAccess fsa, String modelBundleFolder){
		fsa.generateFile(modelBundleFolder + "/module.js", generateModuleForWorkflowHandler().tabsToSpaces(4))
		
		fsa.generateFile(modelBundleFolder + "/manifest.json", generateManifestJsonForWorkflowHandler(dataContainer, processedInput).tabsToSpaces(4))
		
		fsa.generateFile(modelBundleFolder + "/WorkflowEventHandler.js", generateWorkflowEventHandler(dataContainer, processedInput).tabsToSpaces(4))
	}
	
	def generateContentProvidersBundle (IExtendedFileSystemAccess fsa, String contentProviderBundleFolder){
		fsa.generateFile(contentProviderBundleFolder + "/module.js", generateModuleForContentProviders(dataContainer).tabsToSpaces(4))
		fsa.generateFile(contentProviderBundleFolder + "/manifest.json", generateManifestJsonForContentProviders(dataContainer, processedInput).tabsToSpaces(4))
		
		for (contentProvider : dataContainer.contentProviders) {
			fsa.generateFile(contentProviderBundleFolder + "/contentproviders/" + contentProvider.name.toFirstUpper + ".js", generateContentProvider(contentProvider, processedInput).tabsToSpaces(4))
		}
	}
	
	//TODO: Find correct location
//		fsa.copyFileFromProject("resources/images", bundleFolder + "/resources")
	
	override getPlatformPrefix() {
		"mapapps"
	}
	
	override getDefaultSubfolder() {
		"md2_app_" + processedInput.getBasePackageName.split("\\.").reduce[ s1, s2 | s1 + "_" + s2]
	}
	
}
