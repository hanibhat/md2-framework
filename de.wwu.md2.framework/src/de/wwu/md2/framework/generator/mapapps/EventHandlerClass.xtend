package de.wwu.md2.framework.generator.mapapps

import de.wwu.md2.framework.generator.util.DataContainer
import org.eclipse.emf.ecore.resource.ResourceSetimport de.wwu.md2.framework.mD2.CustomAction
import de.wwu.md2.framework.mD2.EventBindingTask
import de.wwu.md2.framework.mD2.WorkflowElement
import de.wwu.md2.framework.mD2.SimpleActionRef
import de.wwu.md2.framework.mD2.FireEventAction
import de.wwu.md2.framework.mD2.WorkflowElementEntry
import de.wwu.md2.framework.mD2.WorkflowEvent
import org.eclipse.emf.common.util.EList
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend2.lib.StringConcatenation

class EventHandlerClass {
	
	def static String generateWorkflowEventHandler(DataContainer dataContainer, ResourceSet processedInput) {
		// TODO: get the right values here...
		'''
			define([
			    "dojo/_base/declare", "ct/Hash"
			],
			function(declare, Hash) {
			    
			    return declare([], {
			        constructor: function() {
			           this.controllers = new Hash();
			        },
			        createInstance: function() {  
			            return {
			              handleEvent: this.handleEvent,
			              addController: this.addController,
			              removeController: this.removeController,
			              instance: this
			            };
			        },
			        
			        handleEvent: function(event, workflowelement) {
			          if
			         «FOR wfe: dataContainer.workflowElements SEPARATOR StringConcatenation::DEFAULT_LINE_DELIMITER + "else if"»
			         «FOR event: getEventsFromWorkflowElement(wfe) SEPARATOR  StringConcatenation::DEFAULT_LINE_DELIMITER + "else if" »
			          (event === "«event.name»" && workflowelement === "«wfe.name»")
			          {  this.instance.controllers.get("md2.wfe.«wfe.name».Controller").closeWindow();
			             this.instance.controllers.get("md2.wfe.«wfe.name».Controller")._isFirstExecution = true;
			             «IF (getNextWorkflowElement(dataContainer, wfe, event) != null)»
			             this.instance.controllers.get("md2.wfe.«getNextWorkflowElement(dataContainer, wfe, event).name».Controller").openWindow();
			         	 «ENDIF»
			          }
			         «ENDFOR»
			         «ENDFOR»

			        },
			        
			        addController: function (controller, properties) {
							this.controllers.set(properties.objectClass[0],controller);
			        },
			        
			        removeController: function (controller, properties) {
			        }
			        
			    });
			});
		'''
	} 
	
	def private static Iterable<WorkflowEvent> getEventsFromWorkflowElement(WorkflowElement wfe)
	{
		var customActions = wfe.actions.filter(CustomAction).map[custAction | custAction.codeFragments].flatten.toSet
		
		var actions = customActions.filter(EventBindingTask).map[tasks | tasks.actions].flatten.toSet

		var fireEventActions = actions.filter(SimpleActionRef).map[ref|ref.action].filter(typeof(FireEventAction))
	
		var events = fireEventActions.map[fea | fea.workflowEvent]
		
		return events
	}
	
	
	def private static WorkflowElement getNextWorkflowElement(DataContainer dataContainer, WorkflowElement wfe, WorkflowEvent e)
	{
		var wfes = dataContainer.workflows.head.workflowElementEntries
		
		for(WorkflowElementEntry entry: wfes)
		{
			if(entry.workflowElement.equals(wfe))
			{
				var searchedEvent = entry.firedEvents.filter[fe | fe.event.name.equals(e.name)].head
				return searchedEvent.startedWorkflowElement
			}
		}
		return null;
	}
	
}