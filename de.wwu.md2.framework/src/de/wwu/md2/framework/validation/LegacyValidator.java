package de.wwu.md2.framework.validation;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.validation.Check;
import org.eclipse.xtext.validation.EValidatorRegistrar;

import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.inject.Inject;

import de.wwu.md2.framework.mD2.AbstractViewGUIElementRef;
import de.wwu.md2.framework.mD2.ActionDrawer;
import de.wwu.md2.framework.mD2.AlternativesPane;
import de.wwu.md2.framework.mD2.AutoGeneratedContentElement;
import de.wwu.md2.framework.mD2.ContainerElement;
import de.wwu.md2.framework.mD2.ContainerElementReference;
import de.wwu.md2.framework.mD2.ContentElement;
import de.wwu.md2.framework.mD2.ContentProvider;
import de.wwu.md2.framework.mD2.ContentProviderAddAction;
import de.wwu.md2.framework.mD2.ContentProviderPath;
import de.wwu.md2.framework.mD2.ContentProviderReference;
import de.wwu.md2.framework.mD2.ContentProviderRemoveAction;
import de.wwu.md2.framework.mD2.Controller;
import de.wwu.md2.framework.mD2.DataType;
import de.wwu.md2.framework.mD2.EntitySelector;
import de.wwu.md2.framework.mD2.FilterType;
import de.wwu.md2.framework.mD2.FlowLayoutPane;
import de.wwu.md2.framework.mD2.GridLayoutPane;
import de.wwu.md2.framework.mD2.GridLayoutPaneColumnsParam;
import de.wwu.md2.framework.mD2.GridLayoutPaneParam;
import de.wwu.md2.framework.mD2.GridLayoutPaneRowsParam;
import de.wwu.md2.framework.mD2.ListView;
import de.wwu.md2.framework.mD2.MD2Model;
import de.wwu.md2.framework.mD2.MD2ModelLayer;
import de.wwu.md2.framework.mD2.MD2Package;
import de.wwu.md2.framework.mD2.Main;
import de.wwu.md2.framework.mD2.ReferencedModelType;
import de.wwu.md2.framework.mD2.SimpleDataType;
import de.wwu.md2.framework.mD2.SimpleType;
import de.wwu.md2.framework.mD2.Spacer;
import de.wwu.md2.framework.mD2.StandardValidator;
import de.wwu.md2.framework.mD2.TabSpecificParam;
import de.wwu.md2.framework.mD2.TabbedAlternativesPane;
import de.wwu.md2.framework.mD2.Validator;
import de.wwu.md2.framework.mD2.ViewElementType;
import de.wwu.md2.framework.mD2.ViewGUIElement;
import de.wwu.md2.framework.mD2.ViewGUIElementReference;
import de.wwu.md2.framework.mD2.WidthParam;
import de.wwu.md2.framework.util.MD2Util;

public class LegacyValidator extends AbstractMD2JavaValidator {

	@Inject
	private ValidatorHelpers helper;

	@Inject
	private MD2Util util;

	@Override
    @Inject
    public void register(EValidatorRegistrar registrar) {
        // nothing to do
    }



	/////////////////////////////////////////////////////////
	/// View layer
	/////////////////////////////////////////////////////////

	/**
	 * Prevent from defining parameters multiple times in any of the view ContainerElements.
	 *
	 * @param containerElement
	 */
	@Check
	public void checkRepeatedParams(ContainerElement containerElement) {
		
		// TabbedAlternativesPane and ListView are container elements without parameters
		if(containerElement instanceof TabbedAlternativesPane || containerElement instanceof ListView) {

			return;
		}

		helper.repeatedParamsError(containerElement, MD2Package.eINSTANCE.getViewElement_Name(), this,
				"GridLayoutPaneRowsParam", "rows", "GridLayoutPaneColumnsParam", "columns",
				"FlowLayoutPaneFlowDirectionParam", "horizontal | vertical",
				"MultiPaneObjectParam", "object", "MultiPaneTextPropositionParam", "textProposition",
				"MultiPaneDisplayAllParam", "displayAll",
				"TabTitleParam", "tabTitle", "TabIconParam", "tabIcon", "TabStaticParam", "static");
	}

	/**
	 * Ensure that tab-specific parameters are only assigned to elements within a tabbed pane.
	 *
	 * @param tabSpecificParam
	 */
	@Check
	public void ensureThatTabParamsOnlyInTabContainer(TabSpecificParam tabSpecificParam) {

		EObject obj = tabSpecificParam.eContainer();
		while (!((obj = obj.eContainer()) instanceof TabbedAlternativesPane) && obj != null);

		// if no parent container of type tabbed pane found
		if(obj == null) acceptWarning("Specifiying a tab-specific parameter outside of a tabbed pane has no effect.", tabSpecificParam, null, -1, null);
	}

	/**
	 * Prevent from defining parameters multiple times in any of the references.
	 *
	 * @param containerRef
	 */
	@Check
	public void checkRepeatedParams(ContainerElementReference containerRef) {
		helper.repeatedParamsError(containerRef, null, this, "TabTitleParam", "tabTitle", "TabIconParam", "tabIcon");
	}

	/**
	 * Assure that the spacer # param is > 0
	 *
	 * @param spacer
	 */
	@Check
	public void checkSpacerNumberParam(Spacer spacer) {
		if(spacer.getNumber() < 1) {
			acceptError("The number param has to be > 0", spacer, MD2Package.eINSTANCE.getSpacer_Number(), -1, null);
		}
	}

	/**
	 * Checks whether a grid layout defines at least the 'rows' or the 'columns' parameter.
	 *
	 * @param gridLayoutPane GridLayout to be checked.
	 */
	@Check
	public void checkThatRowsOrColumnsParamIsSet(GridLayoutPane gridLayoutPane) {

		for(GridLayoutPaneParam param : gridLayoutPane.getParams()) {
			if(param instanceof GridLayoutPaneColumnsParam || param instanceof GridLayoutPaneRowsParam) {
				return;
			}
		}

		acceptError("At least the 'rows' or the 'columns' parameter has to be specified.", gridLayoutPane, null, -1, null);
	}

	/**
	 * Checks if the grid layout contains more than 'rows'x'columns' elements.
	 *
	 * @param gridLayoutPane GridLayout to be checked.
	 */
	@Check
	public void checkWhetherGridLayoutSizeFits(GridLayoutPane gridLayoutPane) {

		int columns = -1;
		int rows = -1;

		for(GridLayoutPaneParam param : gridLayoutPane.getParams()) {
			if(param instanceof GridLayoutPaneColumnsParam) {
				columns = ((GridLayoutPaneColumnsParam)param).getValue();
			}
			else if(param instanceof GridLayoutPaneRowsParam) {
				rows = ((GridLayoutPaneRowsParam)param).getValue();
			}
		}

		// calculate total number of elements in grid layout
		int size = 0;
		for(ViewElementType e : gridLayoutPane.getElements()) {
			if(e instanceof Spacer && ((Spacer)e).getNumber() > 1) {
				size += ((Spacer)e).getNumber();
			} else {
				size++;
			}
		}

		// both parameters are set and there are too few cells for all elements to fit in
		if(columns != -1 && rows != -1 && size > columns * rows) {
			acceptWarning("The grid layout contains more than 'rows'x'columns' elements: " +
					"The grid has " + columns * rows +" cells, but contains " + size + " elements. " +
					"All elements that do not fit in the grid will be omitted.", gridLayoutPane, null, -1, null);
		}
	}

	/**
	 * This validator avoids the reuse of an element (via reference) multiple times without renaming.
	 *
	 * @param ref
	 */
	@Check
	public void avoidReuseOfElementWithoutRenamingGeneric(ContainerElement container) {

		Map<String, Map<Boolean, Set<EObject>>> refrencedObjName = Maps.newHashMap();

		// iterate over all references in the container and store their names in a hash map
		// collect duplicate elements
		for(EObject elem : getElementsOfContainerElement(container)) {
			ViewGUIElement guiElement;
			boolean isRenamed;
			String renameName;

			if(elem instanceof ViewGUIElementReference) {
				guiElement = ((ViewGUIElementReference) elem).getValue();
				isRenamed = ((ViewGUIElementReference) elem).isRename();
				renameName = ((ViewGUIElementReference) elem).getName();
			} else {
				continue;
			}

			// remember all objects in corresponding sets (name -> isRename => set of corresponding elements)
			if(!refrencedObjName.keySet().contains(isRenamed ? renameName : guiElement.getName())) {
				Map<Boolean, Set<EObject>> map = Maps.newHashMapWithExpectedSize(2);
				map.put(true, Sets.<EObject>newHashSet());
				map.put(false, Sets.<EObject>newHashSet());
				refrencedObjName.put(isRenamed ? renameName : guiElement.getName(), map);
			}
			refrencedObjName.get(isRenamed ? renameName : guiElement.getName()).get(isRenamed).add(elem);
		}

		// generate errors if more than one object for a certain name is stored
		for (Map<Boolean, Set<EObject>> map : refrencedObjName.values()) {
			if(map.get(false).size() + map.get(true).size() > 1) {
				for (EObject obj : map.get(false)) {
					acceptError("The same reference has been used multiple times without renaming (use '->' operator).", obj, null, -1, null);
				}
				for (EObject obj : map.get(true)) {
					acceptError("The renamed GUI element has the same name as a referenced GUI element in the same scope.", obj, null, -1, null);
				}
			}
		}
	}

	@Check
	public void checkEntitySelectorContentProviderIsMany(ContentProviderPath contentProviderPathDefinition) {
		if (contentProviderPathDefinition.eContainer() instanceof EntitySelector) {
			if (contentProviderPathDefinition.getContentProviderRef() != null) {
				ContentProvider cp =  contentProviderPathDefinition.getContentProviderRef();
				if (!cp.getType().isMany()) {
					error("The selected ContentProvider is not compatible. Check multiplicities!", MD2Package.eINSTANCE.getContentProviderPath_ContentProviderRef());
				}
			}
		}
	}

	/**
	 * Checks the width attribute of all GUI elements. If the value is 0% or greater than 100% an error is thrown. The default value for the width as
	 * specified in the model (via MD2PostProcessor) is -1, so that the error is only shown if the user set this optional attribute explicitly.
	 *
	 * @param guiElement
	 */
	@Check
	public void checkViewGUIElementWidthIsGreaterZeroAndLessOrEqualThanHundret(ViewGUIElement guiElement) {
		if (guiElement instanceof ContentElement) {
			int width = ((ContentElement) guiElement).getWidth();
			if (width == 0 || width > 100) {
				error("The width parameter may not be " + width + "%. Please set a value between 1% and 100%.", MD2Package.eINSTANCE.getContentElement_Width());
			}
		} else if (guiElement instanceof ContainerElement) {
			// get width parameter from container element
			for (EObject param : getParametersOfContainerElement((ContainerElement)guiElement)) {
				if(param instanceof WidthParam) {
					int width = ((WidthParam) param).getWidth();
					if (width == 0 || width > 100) {
						acceptError("The width parameter may not be " + width + "%. Please set a value between 1% and 100%.", param, null, -1, null);
					}
					break;
				}
			}
		}
	}

	/////////////////////////////////////////////////////////
	/// Controller layer
	/////////////////////////////////////////////////////////

	/**
	 * This validator enforces the declaration of exactly one Main block in each of the
	 * controller files.
	 *
	 * @param controller
	 */
	@Check
	public void ensureThatExactlyOneMainBlockExists(Controller controller) {

		// this list only stores the Main objects of the controller currently validated
		// this information is needed to mark all duplicate Main blocks
		List<Main> mainObjects = null;

		// this counter stores the overall occurrences of main blocks throughout all controllers
		int occurencesOfMain = 0;

		// collect all Main Objects of this controller and count the overall main objects over all controllers
		Collection<MD2Model> md2Models = util.getAllMD2Models(controller.eResource());
		for(MD2Model m : md2Models) {
			MD2ModelLayer ml = m.getModelLayer();
			if(ml instanceof Controller) {
				List<Main> lst = EcoreUtil2.getAllContentsOfType(ml, Main.class);
				occurencesOfMain += lst.size();

				if(ml.eResource().getURI().equals(controller.eResource().getURI())) {
					mainObjects = lst;
				}
			}
		}

		// throw error if not exactly one main block exists
		if(occurencesOfMain == 0 && !md2Models.isEmpty()) {
			error("The Main declaration block is missing", MD2Package.eINSTANCE.getController_ControllerElements());
		} else if(occurencesOfMain > 1 && mainObjects != null) {
			// mark all Main blocks in this controller
			for(Main mainObj : mainObjects) {
				acceptError("Only one Main block is allowed, but " + occurencesOfMain + " have been found", mainObj, null, -1, null);
			}
		}
	}

	@Check
	public void checkForMultiplicityInContentProvider(ContentProvider contentProvider) {
		//if(contentProvider.
	}

	/**
	 * Prevent from defining parameters multiple times in any of the validators.
	 *
	 * @param validator
	 */
	@Check
	public void checkRepeatedParams(Validator validator) {
		helper.repeatedParamsError(validator, MD2Package.eINSTANCE.getValidator_Name(), this, validatorParams());
	}

	/**
	 * Prevent from defining parameters multiple times in any of the standard validators.
	 *
	 * @param validator
	 *
	 */
	@Check
	public void checkRepeatedParams(StandardValidator validator) {
		helper.repeatedParamsError(validator, MD2Package.eINSTANCE.getStandardValidator_Params(), this, validatorParams());
	}

	private String[] validatorParams() {
		return new String[] {
			"ValidatorMessageParam", "message",
			"ValidatorFormatParam", "format",
			"ValidatorRegExParam", "regEx",
			"ValidatorMaxParam", "max", "ValidatorMinParam", "min",
			"ValidatorMaxLengthParam", "maxLenght", "ValidatorMinLengthParam", "minLength"
		};
	}

	/**
	 * Make sure the the ContentProviderPathDefinition for a ReferencedModelType-ContentProvider provides at least one attribute
	 * Mainly used for MappingTasks.
	 * @param pathDef
	 */
	@Check
	public void checkContentProviderPathDefinition(ContentProviderPath pathDef) {
		if (pathDef.getContentProviderRef() != null) {
			if (pathDef.getContentProviderRef().getType() instanceof ReferencedModelType) {
				if (pathDef.getTail() == null) {
					error("No attribute specified", MD2Package.eINSTANCE.getContentProviderPath_ContentProviderRef());
				}
			}
		}
	}

	/**
	 * Make sure the referenced auto-generated element from a Simple-Type-ContentProvider exists
	 * @param abstractRef
	 */
	@Check
	public void checkAbstractViewGUIElementRef_SimpleDataType(AbstractViewGUIElementRef abstractRef) {
		if (abstractRef.getSimpleType() == null) return;
		ArrayList<String> simpleTypes = new ArrayList<String>();
		if (abstractRef.getRef() instanceof AutoGeneratedContentElement) {
			for (ContentProviderReference ref : ((AutoGeneratedContentElement) abstractRef.getRef()).getContentProvider()) {
				ContentProvider cp = ref.getContentProvider();
				if (cp.getType() instanceof SimpleType) {
					SimpleDataType type = ((SimpleType) cp.getType()).getType();
					if (type == abstractRef.getSimpleType().getType()) return;
					else simpleTypes.add(type.toString());
				}
			}
		}
		String warning = "No such element exists.";
		if (simpleTypes.size() > 0) warning += " Choose from: " + simpleTypes;
		error(warning, MD2Package.eINSTANCE.getAbstractViewGUIElementRef_SimpleType());
	}

	/**
	 * Prevent user from referencing an AutoGeneratorContentElement
	 * @param abstractRef
	 */
	@Check
	public void checkAbstractViewGUIElementRef_Path(AbstractViewGUIElementRef abstractRef) {
		if (abstractRef.getRef() instanceof AutoGeneratedContentElement && abstractRef.getPath() == null && abstractRef.getSimpleType() == null) {
			warning("No attribute specified.", MD2Package.eINSTANCE.getAbstractViewGUIElementRef_Path());
		}
	}

	/**
	 * This validator avoids the assignment of none-toMany content providers (providing X[]) to ContentProviderAddActions.
	 * @param addAction
	 */
	@Check
	public void checkForAssignmentsOfSingleElementContentProvidersToContentProviderAddActions(ContentProviderAddAction addAction) {

		ContentProvider contentProvider = addAction.getContentProviderTarget().getContentProvider();

		if(!contentProvider.getType().isMany()) {
			acceptError("Tried to add an element to a content provider of type '" + getDataTypeName(contentProvider.getType())
					+ "', but expected an is-many content provider " + getDataTypeName(contentProvider.getType()) + "[].",
					addAction, MD2Package.eINSTANCE.getContentProviderAddAction_ContentProviderTarget(), -1, null);
		}

		 ContentProvider sp = addAction.getContentProviderSource().getContentProvider();

		 if(sp.getType().isMany()) {
				acceptError("Tried to use a MultiContentProvider as source for addAction, only single ContenProvider allowed",
						addAction, MD2Package.eINSTANCE.getContentProviderAddAction_ContentProviderSource(), -1, null);
			}

	}

	/**
	 * This validator avoids the assignment of none-toMany content providers (providing X[]) to ContentProviderRemoveActions.
	 * @param removeAction
	 */
	@Check
	public void checkForAssignmentsOfSingleElementContentProvidersToContentProviderRemoveActions(ContentProviderRemoveAction removeAction) {

		ContentProvider contentProvider = removeAction.getContentProvider().getContentProvider();

		if(!contentProvider.getType().isMany()) {
			acceptError("Tried to remove an element from a content provider of type '" + getDataTypeName(contentProvider.getType())
					+ "', but expected an is-many content provider " + getDataTypeName(contentProvider.getType()) + "[].",
					removeAction, MD2Package.eINSTANCE.getContentProviderRemoveAction_ContentProvider(), -1, null);
		}
	}

	public static final String FILTERMULTIPLIYITY = "filtermultipliyity";

	/**
	 * Avoid the assignment of 'all' filters to single-instance content providers.
	 * @param contentProvider
	 */
	@Check
	public void checkFilterMultiplicity(ContentProvider contentProvider) {
		if(!contentProvider.getType().isMany() && contentProvider.isFilter() && contentProvider.getFilterType().equals(FilterType.ALL)) {
			acceptError("The filter type 'all' cannot be assigned to content providers that only return a single " +
				"instance. Change parameter to 'first'.", contentProvider, MD2Package.eINSTANCE.getContentProvider_FilterType(), -1, FILTERMULTIPLIYITY);
		}
	}


	/////////////////////////////////////////////////////////
	/// Private helpers
	/////////////////////////////////////////////////////////

	private Set<EObject> getElementsOfContainerElement(ContainerElement container) {

		Set<EObject> elements = Sets.newHashSet();

		if(container instanceof GridLayoutPane) {
			elements.addAll(((GridLayoutPane) container).getElements());
		} else if(container instanceof FlowLayoutPane) {
			elements.addAll(((FlowLayoutPane) container).getElements());
		} else if(container instanceof AlternativesPane) {
			elements.addAll(((AlternativesPane) container).getElements());
		} else if(container instanceof TabbedAlternativesPane) {
			elements.addAll(((TabbedAlternativesPane) container).getElements());
		} else if(container instanceof ListView){
			elements.addAll(((ListView) container).getElements());
		} else if(container instanceof ActionDrawer){
			// do nothing
		} else {
			System.err.println("Unexpected ContainerElement subtype found: " + container.getClass().getName());
		}

		return elements;
	}

	private Set<EObject> getParametersOfContainerElement(ContainerElement container) {

		Set<EObject> parameters = Sets.newHashSet();

		if(container instanceof GridLayoutPane) {
			parameters.addAll(((GridLayoutPane) container).getParams());
		} else if(container instanceof FlowLayoutPane) {
			parameters.addAll(((FlowLayoutPane) container).getParams());
		} else if(container instanceof AlternativesPane) {
			parameters.addAll(((AlternativesPane) container).getParams());
		} else if(container instanceof TabbedAlternativesPane) {
			// has no parameters
		} else if(container instanceof ListView) {
			// has no used parameters
		} else if(container instanceof ActionDrawer){
			// do nothing
		} else {
			System.err.println("Unexpected ContainerElement subtype found: " + container.getClass().getName());
		}

		return parameters;
	}

	private String getDataTypeName(DataType dataType) {

		String str = "";

		if(dataType instanceof ReferencedModelType) {
			str = ((ReferencedModelType) dataType).getEntity().getName();
		} else if(dataType instanceof SimpleType) {
			str = ((SimpleType) dataType).getType().getLiteral();
		} else {
			System.err.println("Unexpected DataType found: " + dataType.getClass().getName());
		}

		return str;
	}

}
