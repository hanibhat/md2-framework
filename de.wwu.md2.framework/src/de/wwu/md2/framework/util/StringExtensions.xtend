package de.wwu.md2.framework.util

class StringExtensions {
	
	/**
	 * If the string is embraced by parentheses (...), the same string without the embracing
	 * parentheses is returned.
	 */
	def static trimParentheses(String str) {
		if (str == null) {
			return str;
		} else if (str.startsWith("(") && str.endsWith(")")) {
			return str.substring(1, str.length() - 1);
		}
		return str;
	}
	
	/**
	 * Surround a given string with quotes.
	 */
	def static quotify(String str) {
		if (str == null) {
			return str;
		}
		return '''"«str»"'''
	}
	
}