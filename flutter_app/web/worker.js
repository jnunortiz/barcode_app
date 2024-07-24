self.onmessage = function(event) {
    const data = event.data;
    if (data.type === 'process') {
      // Process data.content
      // Example: Simulate processing delay
      setTimeout(() => {
        const processedContent = data.content.toUpperCase(); // Example processing
        self.postMessage({ type: 'result', content: processedContent });
      }, 1000); // Simulate 1 second processing time
    }
  };
  