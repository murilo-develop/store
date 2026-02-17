import { Controller } from "@hotwired/stimulus"

/**
 * Alert Dismiss Controller
 * Handles automatic and manual dismissal of alert messages with fade-out animation
 */
export default class extends Controller {
  // Define a configurable delay value (in milliseconds) for auto-dismissal
  static values = { delay: Number }
  
  /**
   * Initialize the controller when it's connected to the DOM
   * If a delay value is set, automatically close the alert after the specified time
   */
  connect() {
    if (this.hasDelayValue && this.delayValue > 0) {
      // Store timeout reference for cleanup on disconnect
      this.timeout = setTimeout(() => {
        this.close()
      }, this.delayValue)
    }
  }
  
  /**
   * Close the alert with a smooth fade-out animation
   * This method can be called manually (e.g., via a close button) or automatically via timeout
   */
  close() {
    // Apply fade-out transition effect
    this.element.style.transition = "opacity 300ms ease-out"
    this.element.style.opacity = "0"
    
    // Remove element from DOM after animation completes (300ms)
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
  
  /**
   * Cleanup when controller is disconnected from the DOM
   * Prevents memory leaks by clearing any pending timeouts
   */
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}