package de.wwu.md2.framework.generator.android.lollipop.controller

import de.wwu.md2.framework.generator.IExtendedFileSystemAccess
import de.wwu.md2.framework.generator.android.common.util.MD2AndroidUtil
import de.wwu.md2.framework.generator.android.lollipop.Settings
import de.wwu.md2.framework.mD2.App
import de.wwu.md2.framework.mD2.AttrSensorAxis
import de.wwu.md2.framework.mD2.AttrSensorTyp
import de.wwu.md2.framework.mD2.Button
import de.wwu.md2.framework.mD2.Entity
import de.wwu.md2.framework.mD2.GridLayoutPane
import de.wwu.md2.framework.mD2.IntegerInput
import de.wwu.md2.framework.mD2.Label
import de.wwu.md2.framework.mD2.ListView
import de.wwu.md2.framework.mD2.SensorType
import de.wwu.md2.framework.mD2.TextInput
import de.wwu.md2.framework.mD2.ViewElementType
import de.wwu.md2.framework.mD2.ViewFrame
import de.wwu.md2.framework.mD2.ViewGUIElementReference
import de.wwu.md2.framework.mD2.WorkflowElementReference
import de.wwu.md2.framework.mD2.Image

class ActivityGen {
	
	def static generateActivities(IExtendedFileSystemAccess fsa, String rootFolder, String mainPath, String mainPackage,
		Iterable<ViewFrame> frames, Iterable<WorkflowElementReference> startableWorkflowElements, Iterable<Entity> entities, App app) {
		
		fsa.generateFile(rootFolder + Settings.JAVA_PATH + mainPath + "StartActivity.java",
				generateStartActivity(mainPackage, startableWorkflowElements))	
		
		frames.forEach [ frame |
			fsa.generateFile(rootFolder + Settings.JAVA_PATH + mainPath + frame.name.toFirstUpper + "Activity.java",
				generateActivity(mainPackage, entities, frame))
				
				if (frame.elements.filter(ListView).length > 0){
					fsa.generateFile(rootFolder + Settings.JAVA_PATH + mainPath + frame.name.toFirstUpper + "ListAdapter.java",
					generateListAdapter(mainPackage, frame, app))
				}
		]
		
	}
	
		//generiert ListAdapter für Inhalt einer Listenansicht
	def static generateListAdapter(String mainPackage, ViewFrame frame, App app)'''
		«val ListView list = frame.elements.filter(ListView).get(0)»
		//generated in de.wwu.md2.framework.generator.android.lollipop.controller.Activity.generateListAdapter()

		package «mainPackage»;
		
		import android.content.Context;
		import android.graphics.Color;
		import android.graphics.Point;
		import android.view.Display;
		import android.view.Gravity;
		import android.view.WindowManager;
		import android.support.v7.widget.RecyclerView;
		import android.view.View;
		import android.view.ViewGroup;
		import «Settings.MD2LIBRARY_PACKAGE»controller.eventhandler.implementation.Md2ButtonOnSwipeHandler;
		import «Settings.MD2LIBRARY_PACKAGE»controller.eventhandler.implementation.Md2OnClickHandler;
		import «Settings.MD2LIBRARY_PACKAGE»view.widgets.implementation.Md2Button;
		import «Settings.MD2LIBRARY_PACKAGE»controller.action.interfaces.Md2Action;
		import «Settings.MD2LIBRARY_PACKAGE»model.contentProvider.implementation.Md2ContentProviderRegistry;
		import «Settings.MD2LIBRARY_PACKAGE»model.contentProvider.interfaces.Md2ContentProvider;
		import «Settings.MD2LIBRARY_PACKAGE»model.contentProvider.interfaces.Md2MultiContentProvider;
		import «Settings.MD2LIBRARY_PACKAGE»controller.action.implementation.Md2UpdateListIndexAction;
		import «Settings.MD2LIBRARY_PACKAGE»controller.action.implementation.Md2RefreshListAction;
		
		«IF(!(list.onClickAction === null))»
			import «mainPackage».md2.controller.action.«MD2AndroidUtil.getQualifiedNameAsString(list.onClickAction, "_").toFirstUpper»_Action;
		«ENDIF»
		«IF(!(list.leftSwipeAction === null))»
			import «mainPackage».md2.controller.action.«MD2AndroidUtil.getQualifiedNameAsString(list.leftSwipeAction, "_").toFirstUpper»_Action;
		«ENDIF»
		«IF(!(list.rightSwipeAction === null))»
			import «mainPackage».md2.controller.action.«MD2AndroidUtil.getQualifiedNameAsString(list.rightSwipeAction, "_").toFirstUpper»_Action;
		«ENDIF»
		
		public class «frame.name.toFirstUpper»ListAdapter extends RecyclerView.Adapter{
			
			private Md2MultiContentProvider content;
			private Md2ButtonOnSwipeHandler swipeHandler;
			private Md2OnClickHandler clickHandler;
			
			public Md2ButtonOnSwipeHandler getOnSwipeHandler(){
				return swipeHandler;
			}
			
			public Md2OnClickHandler getOnClickHandler(){
				return clickHandler;
			}
			
			public «frame.name.toFirstUpper»ListAdapter(){
				content = Md2ContentProviderRegistry.getInstance().getContentMultiProvider("«list.connectedProvider.contentProviderRef.name»");
				content.addAdapter(this, "«frame.name»ListAdapter");
				swipeHandler = new Md2ButtonOnSwipeHandler();
				clickHandler = new Md2OnClickHandler();
				«IF(!(list.onClickAction === null))»
					Md2Action ca = new «MD2AndroidUtil.getQualifiedNameAsString(list.onClickAction, "_").toFirstUpper»_Action();
					clickHandler.registerAction(ca);
				«ENDIF»
				«IF(!(list.leftSwipeAction === null))»
					Md2Action lsa = new «MD2AndroidUtil.getQualifiedNameAsString(list.leftSwipeAction, "_").toFirstUpper»_Action();
					swipeHandler.getLeftSwipeHandler().registerAction(lsa);
				«ENDIF»
				«IF(!(list.rightSwipeAction === null))»
					Md2Action rsa = new «MD2AndroidUtil.getQualifiedNameAsString(list.rightSwipeAction, "_").toFirstUpper»_Action();
					swipeHandler.getRightSwipeHandler().registerAction(rsa);
				«ENDIF»
			}
			
			@Override
			public void onBindViewHolder(RecyclerView.ViewHolder vh, int i){
				ListItem li = (ListItem) vh;
				if(content.getValue(i,"«list.connectedProvider.tail.attributeRef.name»") != null){
					li.getButton().setText(content.getValue(i,"«list.connectedProvider.tail.attributeRef.name»").getString().toString());
				} else {
					li.getButton().setText("Fehler");
				}
				//Listener hinzufuegen
				Md2UpdateListIndexAction indexAction = new Md2UpdateListIndexAction("«list.name»", i, content);
				Md2OnClickHandler ch = new Md2OnClickHandler();
				Md2ButtonOnSwipeHandler sw = new Md2ButtonOnSwipeHandler();
				ch.registerAction(indexAction);
				ch.addActions(clickHandler.getActions());
				sw.registerAction(indexAction, true);
				sw.registerAction(indexAction, false);
				sw.getLeftSwipeHandler().addActions(swipeHandler.getLeftSwipeHandler().getActions());
				sw.getRightSwipeHandler().addActions(swipeHandler.getRightSwipeHandler().getActions());
				Md2RefreshListAction rflaction = new Md2RefreshListAction(this);
				ch.registerAction(rflaction);
				sw.registerAction(rflaction, true);
				sw.registerAction(rflaction, false);
				li.getButton().setOnClickHandler(ch);
				li.getButton().setOnSwipeHandler(sw);
			}
			
			@Override
			public int getItemCount() {
				return content.getContents().size();
			}
			
			@Override
			public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup vg, int i){
				Md2Button b = new Md2Button (vg.getContext());
				ListItem li = new ListItem(b);
				return li;
			}
			
			public class ListItem extends RecyclerView.ViewHolder{
				
				private Md2Button button;
				
				public ListItem(View itemView){
					super(itemView);
					button = (Md2Button) itemView;
					button.setBackgroundColor(Color.TRANSPARENT);
					WindowManager wm = (WindowManager) «app.name.toFirstUpper».getAppContext().getSystemService(Context.WINDOW_SERVICE);
					Display display = wm.getDefaultDisplay();
					Point size = new Point();
					display.getSize(size);
					int width = size.x;
					button.setWidth(width);
					button.setGravity(Gravity.LEFT);
				}
				
				public Md2Button getButton(){
					return button;
				}
				
				
			}
			
		}
		
	'''

	def static generateStartActivity(String mainPackage, Iterable<WorkflowElementReference> startableWorkflowElements)'''
		// generated in de.wwu.md2.framework.generator.android.lollipop.controller.Activity.generateStartActivity()
		package «mainPackage»;
		
		import android.app.Activity;
		import android.content.Intent;
		import android.os.Bundle;
		import android.view.View;
		
		import «mainPackage».md2.controller.Controller;
		import «Settings.MD2LIBRARY_VIEWMANAGER_PACKAGE_NAME»;
		import «Settings.MD2LIBRARY_WIDGETREGISTRY_PACKAGE_NAME»;
		import «Settings.MD2LIBRARY_TASKQUEUE_PACKAGE_NAME»;
		«MD2AndroidUtil.generateImportAllWidgets»
		«MD2AndroidUtil.generateImportAllTypes»
		«MD2AndroidUtil.generateImportAllEventHandler»
		
		«FOR wer : startableWorkflowElements»		        	
			import «mainPackage».md2.controller.action.«wer.workflowElementReference.name.toFirstUpper»___«wer.workflowElementReference.name.toFirstUpper»_startupAction_Action;
		«ENDFOR»
		
		import «Settings.MD2LIBRARY_PACKAGE»controller.action.implementation.Md2GoToViewAction;
		
		public class StartActivity extends Activity {
		
		    @Override
		    protected void onCreate(Bundle savedInstanceState) {
		        super.onCreate(savedInstanceState);
		        setContentView(R.layout.activity_start);
		        «FOR wer : startableWorkflowElements»
		        	Md2Button «wer.workflowElementReference.name»Button = (Md2Button) findViewById(R.id.startActivity_«wer.workflowElementReference.name»Button);
		        	«wer.workflowElementReference.name»Button.setWidgetId(R.id.startActivity_«wer.workflowElementReference.name»Button);
		        	Md2WidgetRegistry.getInstance().addWidget(«wer.workflowElementReference.name»Button);
		        «ENDFOR»
		    }
		
		    @Override
		    protected void onStart(){
				super.onStart();
				Md2ViewManager.getInstance().setActiveView(this);
		        
		        // TODO move startableWorkflowElements to Md2WorkflowManager
				«FOR wer : startableWorkflowElements»
					Md2Button «wer.workflowElementReference.name»Button = (Md2Button) findViewById(R.id.startActivity_«wer.workflowElementReference.name»Button);
					«wer.workflowElementReference.name»Button.getOnClickHandler().registerAction(new «wer.workflowElementReference.name.toFirstUpper»___«wer.workflowElementReference.name.toFirstUpper»_startupAction_Action());
		        «ENDFOR»
				Md2TaskQueue.getInstance().tryExecutePendingTasks();
		    }
		    
			@Override
		    protected void onPause(){
		        super.onPause();
			«FOR wer : startableWorkflowElements»
				Md2Button «wer.workflowElementReference.name»Button = (Md2Button) findViewById(R.id.startActivity_«wer.workflowElementReference.name»Button);
				Md2WidgetRegistry.getInstance().saveWidget(«wer.workflowElementReference.name»Button);
			«ENDFOR»
		    }
		    
		    @Override
			public void onBackPressed() {
				// remain on start screen
			}
		}
	'''

	private def static generateActivity(String mainPackage, Iterable<Entity> entities, ViewFrame frame) '''
		// generated in de.wwu.md2.framework.generator.android.lollipop.controller.Activity.generateActivity()
		package «mainPackage»;
		
		import android.app.Activity;
		import android.content.Intent;
		import android.os.Bundle;
		import android.view.View;
		««« Accessibility R16
		import android.view.Menu;
		import android.view.MenuInflater;
		import android.view.MenuItem;
		
		import android.support.v7.widget.RecyclerView;
		import android.support.v7.widget.LinearLayoutManager;
		import android.support.v7.widget.DividerItemDecoration;
		import android.support.v7.widget.DefaultItemAnimator;
		
		import de.wwu.md2.android.md2library.SensorHelper; // TODO Generalize
		import «mainPackage».md2.controller.Controller;
		import «Settings.MD2LIBRARY_VIEWMANAGER_PACKAGE_NAME»;
		import «Settings.MD2LIBRARY_WIDGETREGISTRY_PACKAGE_NAME»;
		import «Settings.MD2LIBRARY_TASKQUEUE_PACKAGE_NAME»;
		«MD2AndroidUtil.generateImportAllWidgets»
		«MD2AndroidUtil.generateImportAllTypes»
		«MD2AndroidUtil.generateImportAllEventHandler»
		import android.widget.ImageView; // For camera actions
		import «Settings.MD2LIBRARY_PACKAGE»controller.action.implementation.Md2CameraAction;
		
				
		public class «frame.name.toFirstUpper»Activity extends Activity {
		
			private RecyclerView wrv;
		
			@Override
			protected void onCreate(Bundle savedInstanceState) {
				super.onCreate(savedInstanceState);
				setContentView(R.layout.activity_«frame.name.toLowerCase»);
		        «FOR viewElement: frame.eAllContents.filter(ViewElementType).toIterable»
					«generateAddViewElement(viewElement)»
		        «ENDFOR»

		        «IF (frame.elements.filter(ListView).length > 0)»
		        wrv = (RecyclerView) findViewById(R.id.recycler_view_«frame.name»);
		        
		        final LinearLayoutManager layoutManager = new LinearLayoutManager(getApplicationContext());
		        layoutManager.setOrientation(LinearLayoutManager.VERTICAL);
		        wrv.setLayoutManager(layoutManager);
		        
		        «frame.name.toFirstUpper»ListAdapter listAdapter = new «frame.name.toFirstUpper»ListAdapter();
		        wrv.setAdapter(listAdapter);
		        
		        wrv.addItemDecoration(new DividerItemDecoration(
		        	wrv.getContext(),
		        	layoutManager.getOrientation()
		        ));
		        wrv.setItemAnimator(new DefaultItemAnimator());
				«ENDIF»
			}
		
			//HardwareSensoren
			«generateSensorDef(entities)»
		
		    @Override
		    protected void onStart(){
				super.onStart();
		        Md2ViewManager.getInstance().setActiveView(this);
		        
		        «FOR viewElement: frame.eAllContents.filter(ViewElementType).toIterable»
		        	«generateLoadViewElement(viewElement)»
		        «ENDFOR»
		        
		        //HardwareSensoren
		        «generateSensor(entities)»
		        
		        Md2TaskQueue.getInstance().tryExecutePendingTasks();
		    }
		    
			@Override
		    protected void onPause(){
		        super.onPause();
		        «FOR viewElement: frame.eAllContents.filter(ViewElementType).toIterable»
		        	«generateSaveViewElement(viewElement)»
		        «ENDFOR»
		    }
		    
			««« Accessibility R16
		    @Override
	        public boolean onCreateOptionsMenu(Menu menu) {
	            MenuInflater inflater = getMenuInflater();
	            inflater.inflate(R.menu.main_menu, menu);
	            return true;
	        }
	    
	        @Override
	        public boolean onOptionsItemSelected(MenuItem item) {
	            // Handle item selection
	            switch (item.getItemId()) {
	                case R.id.mainMenu_HomeBtn:
	                    Md2ViewManager.getInstance().goTo(getString(R.string.StartActivity));
	                    return true;
	                default:
	                    return super.onOptionsItemSelected(item);
	            }
	        }
		    
		    @Override
			public void onBackPressed() {
				// go back to start screen
				Md2ViewManager.getInstance().goTo(getString(R.string.StartActivity));
			}
			
			«IF (frame.elements.filter(Image).size() > 0)»
			@Override
			protected void onActivityResult(int requestCode, int resultCode, Intent data) {
				// Check which request we're responding to
				if (requestCode == Md2CameraAction.REQUEST_TAKE_PHOTO) {
					// Make sure the request was successful
					if (resultCode == Activity.RESULT_OK) {
						// The user picked a photo.
						ImageView imageView = (ImageView) findViewById(R.id.«MD2AndroidUtil.getQualifiedNameAsString(frame.elements.filter(Image).head, "_")»);
						Md2CameraAction.callback(imageView);
					}
				}
			}
			«ENDIF»
		}
	'''
	
	private static def String generateAddViewElement(ViewElementType vet){
		var String result = ""
		var String type = ""
		
		var qualifiedName = MD2AndroidUtil.getQualifiedNameAsString(vet, "_")
		if(qualifiedName === null || qualifiedName.empty)
			return ""
		
		switch vet{
			ViewGUIElementReference: return generateSaveViewElement(vet.value)			
			default: type = getCustomViewTypeNameForViewElementType(vet)			
		}
		
		if(type === null || type.empty)
			return ""
		
		result = '''
			«type» «qualifiedName.toFirstLower» = («type») findViewById(R.id.«qualifiedName»);
			«qualifiedName.toFirstLower».setWidgetId(R.id.«qualifiedName»);
			Md2WidgetRegistry.getInstance().addWidget(«qualifiedName.toFirstLower»);
        '''
        return result
	}
	
	private static def String generateLoadViewElement(ViewElementType vet){
		var String result = ""
		var String type = ""
		
		var qualifiedName = MD2AndroidUtil.getQualifiedNameAsString(vet, "_")
		if(qualifiedName === null || qualifiedName.empty)
			return ""		
		
		switch vet{
			ViewGUIElementReference: return generateSaveViewElement(vet.value)			
			default: type = getCustomViewTypeNameForViewElementType(vet)			
		}
		
		if(type === null || type.empty)
			return ""
		
		result = '''
			«type» «qualifiedName.toFirstLower» = («type») findViewById(R.id.«qualifiedName»);
			Md2WidgetRegistry.getInstance().loadWidget(«qualifiedName.toFirstLower»);
        '''
        
		return result
	}
	
	private static def String generateSaveViewElement(ViewElementType vet){
		var String result = ""
		var String type = ""
		
		var qualifiedName = MD2AndroidUtil.getQualifiedNameAsString(vet, "_")
		if(qualifiedName === null || qualifiedName.empty)
			return ""		
		
		switch vet{
			ViewGUIElementReference: return generateSaveViewElement(vet.value)			
			default: type = getCustomViewTypeNameForViewElementType(vet)			
		}
		
		if(type === null || type.empty)
			return ""
		
		result = '''
			«type» «qualifiedName.toFirstLower» = («type») findViewById(R.id.«qualifiedName»);
			Md2WidgetRegistry.getInstance().saveWidget(«qualifiedName.toFirstLower»);
        '''
        
		return result
	}
	
	private static def String getCustomViewTypeNameForViewElementType(ViewElementType vet){
		switch vet{
			ViewGUIElementReference: return generateSaveViewElement(vet.value)
			GridLayoutPane:
				return "Md2GridLayoutPane"
			Button:
				return "Md2Button"
			Label:
				return "Md2Label"
			TextInput:
				return "Md2TextInput"
			IntegerInput:
				return "Md2TextInput"
			default: return ""
		}
	}
	
	/**
	 * generateSensor erwartet die Entites aus dem MD2 Modell, um daraus die entsprechenden
	 * Attribute, die als Sensor, gekenzeichnet sind zu generieren. Der fertig generierte Code
	 * wird als String zurückgegeben.
	 */
	private static def String generateSensor(Iterable<Entity> entities){
		var String result = "";
		//Alle Entities durchgehen
		for (e : entities) {
			for (attribute : e.attributes){
				//Nur Attribute vom Typ Sensor bearbeiten
				if(attribute.type instanceof SensorType){
					//Parameter durchgehen
					for(param : (attribute.type as SensorType).params){
						//Parameter vom AttrSensorTyp
						if(param instanceof AttrSensorTyp){
							if(param.accelerometer){
								result += ("SensorHelper meinSensorHelper_" + attribute.name +" = new SensorHelper(this, \"" + attribute.name + "\", \"accelerometer\", \"");
							}
							if(param.gyroskop){
								result += ("SensorHelper meinSensorHelper_" + attribute.name +" = new SensorHelper(this, \"" + attribute.name + "\", \"gyroskop\", \"")
							}
							if(param.heartrate){
								result += ("SensorHelper meinSensorHelper_" + attribute.name +" = new SensorHelper(this, \"" + attribute.name + "\", \"heartrate\");\r\n")
							}
							if(param.proximity){
								result += ("SensorHelper meinSensorHelper_" + attribute.name +" = new SensorHelper(this, \"" + attribute.name + "\", \"proximity\");\r\n")
							}
						}
						//Parameter vom AttrSensorAxis
						if(param instanceof AttrSensorAxis){
							if(param.x){result += ("X\");\r\n")}
							if(param.y){result += ("Y\");\r\n")}
							if(param.z){result += ("Z\");\r\n")}
						}
					}
				}
			}
			println(result)
			return result;
		}
	}
	
	private static def String generateSensorDef(Iterable<Entity> entities){
		var String result = "";
		for(attribute : entities.flatMap[it.attributes].filter[it.type instanceof SensorType]){
			for(param : (attribute.type as SensorType).params.filter(AttrSensorTyp).map[it as AttrSensorTyp]){
				result += ("SensorHelper meinSensorHelper_" + attribute.name +";")
			}
		}
		return result
	}
}