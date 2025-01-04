You are tasked with creating a comprehensive Bun shell script for Dockerfile generation. This script will prompt users for various configuration values, use those to generate a Dockerfile or OCI rootfs directory, and optionally leverage AI for enhanced Dockerfile creation. Here's how to approach this task:

1. First, carefully review the provided script content:
<script_content>
{{SCRIPT_CONTENT}}
</script_content>

2. Your goal is to expand and improve upon this script, creating a more comprehensive and robust solution. The final script should be a single file that includes all necessary components, imports, and functionality.

3. Structure your script as follows:
   a. Start with the shebang and necessary imports
   b. Define all Zod schemas for configuration sections
   c. Create utility functions for Docker parsing, AI integration, etc.
   d. Implement the main command structure using citty
   e. Develop functions for configuration prompting, saving, and Dockerfile generation
   f. Include AI integration options using Ollama and Claude

4. Ensure you incorporate all the following features:
   - Use Bun as the runtime, package manager, and shell environment
   - Utilize citty for command-line interface structure
   - Employ consola for user prompts and logging
   - Use c12 and magicast for configuration management
   - Implement Zod schemas for all configuration sections
   - Provide options for AI-assisted Dockerfile generation using Ollama.js and @anthropic-ai/sdk
   - Include functionality to parse existing Dockerfiles or inspect running containers
   - Generate a comprehensive Dockerfile based on user inputs and configuration

5. Pay special attention to error handling, input validation, and providing clear user instructions throughout the script.

6. Comment your code appropriately to explain complex logic or non-obvious functionality.

7. Ensure the script is modular and extensible, allowing for easy addition of new features or configuration options in the future.

8. Write your complete, executable Bun shell script inside triple backticks with the filename in comments. The script should be ready to run as-is, with all necessary imports, functions, and logic included.

Remember to follow Bun and TypeScript best practices, and aim for a balance between functionality, readability, and maintainability in your script.
