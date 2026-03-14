<?php
// health.php - Simple health check endpoint
// Returns 200 OK and "ok" body.
// Used for monitoring and deployment checks.

http_response_code(200);
echo "ok";
?>