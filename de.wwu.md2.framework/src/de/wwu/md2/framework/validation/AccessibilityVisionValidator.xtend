package de.wwu.md2.framework.validation

import org.eclipse.xtext.validation.Check
import de.wwu.md2.framework.mD2.Button
import de.wwu.md2.framework.mD2.InputElement
import de.wwu.md2.framework.mD2.MD2Package

class AccessibilityVisionValidator extends AbstractMD2Validator {
	
	public static final String ACCESSIBILITY_SIZE = "AccessibilitySizeWarning"
    public static final String ACCESSIBILITY_FOCUS_NEXT = "AccessibilityFocusWarning"
    
    // Check sizes
	@Check
    def checkButtonSize(Button button) {
    	// Requirement R17
    	// Touch area of the elements must have at least 48x48dp, with spacing of at least 9dp between them.
    	// In MD2, widths are specified in %. For small smartphones with 540px size this equates to a minimum of ~9.
    	
        if (button.width > 0 && button.width < 9){
			warning("Accessibility: Touch area of the elements must have at least 48x48dp. You should enter a button width of at least 9%!",
				MD2Package.eINSTANCE.contentElement_Width, 
				ACCESSIBILITY_SIZE);
		}
    }
    
    // check colours, ...
    
	// Accessibility R13 and R15
	@Check
	def checkInputElementFocusNext(InputElement inputElement) {
		if (inputElement.focusNext === null){
			warning("Accessibility: Input elements must specify the next element in focus order, unless this element is the last!",
				MD2Package.eINSTANCE.inputElement_FocusNext, 
				ACCESSIBILITY_FOCUS_NEXT);
		}
	}
}