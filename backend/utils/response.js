// Standard Error Response Helper
// Use this across all route files for consistent error handling

/**
 * Send a standardized success response
 * @param {Object} res - Express response object
 * @param {Object} data - Data to send
 * @param {number} statusCode - HTTP status code (default: 200)
 */
const sendSuccess = (res, data = {}, statusCode = 200) => {
    res.status(statusCode).json({
        success: true,
        ...data
    });
};

/**
 * Send a standardized error response
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @param {number} statusCode - HTTP status code (default: 500)
 * @param {Object} error - Optional error object for debugging
 */
const sendError = (res, message, statusCode = 500, error = null) => {
    const response = {
        success: false,
        message
    };

    // Include error details in development mode
    if (process.env.NODE_ENV === 'development' && error) {
        response.error = error.message || error;
    }

    res.status(statusCode).json(response);
};

/**
 * Handle async route errors consistently
 * @param {Function} fn - Async route handler
 */
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((error) => {
        console.error('Route error:', error);
        sendError(res, 'Server error', 500, error);
    });
};

module.exports = {
    sendSuccess,
    sendError,
    asyncHandler
};
