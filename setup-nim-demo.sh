#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting NIM Demo Setup...${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed. Please install Node.js first.${NC}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is not installed. Please install npm first.${NC}"
    exit 1
fi

# Check if AWS Amplify CLI is installed
if ! command -v amplify &> /dev/null; then
    echo -e "${BLUE}Installing AWS Amplify CLI...${NC}"
    npm install -g @aws-amplify/cli
fi

# Create project directory
PROJECT_NAME="react-amplify-nim-demo"
echo -e "${BLUE}Creating new React project: ${PROJECT_NAME}${NC}"

# Create React app
npx create-react-app $PROJECT_NAME
cd $PROJECT_NAME

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
npm install aws-amplify @aws-amplify/ui-react axios @aws-amplify/ui-components

# Create src directory structure
mkdir -p src/components
mkdir -p src/config
mkdir -p src/styles

# Create configuration file
cat > src/config/config.js << EOL
export const nimConfig = {
    apiEndpoint: process.env.REACT_APP_NIM_API_ENDPOINT || 'http://localhost:50051',
    apiKey: process.env.REACT_APP_NIM_API_KEY || 'your-api-key'
};
EOL

# Create environment file
cat > .env << EOL
REACT_APP_NIM_API_ENDPOINT=http://localhost:50051
REACT_APP_NIM_API_KEY=your-api-key
EOL

# Create improved App.js with better styling and error handling
cat > src/App.js << EOL
import React, { useState } from 'react';
import { Amplify } from 'aws-amplify';
import { ThemeProvider, Button, TextAreaField, Heading, View, Alert } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import { nimConfig } from './config/config';

Amplify.configure({
  // Add your Amplify configuration here if needed
});

function App() {
  const [inputText, setInputText] = useState('');
  const [translatedText, setTranslatedText] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleTranslate = async () => {
    if (!inputText.trim()) {
      setError('Please enter some text to translate');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await fetch(\`\${nimConfig.apiEndpoint}/v1/translate\`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': \`Bearer \${nimConfig.apiKey}\`,
        },
        body: JSON.stringify({
          text: inputText,
          source_language: 'en',
          target_language: 'en',
        }),
      });

      if (!response.ok) {
        throw new Error(\`HTTP error! status: \${response.status}\`);
      }

      const data = await response.json();
      setTranslatedText(data.translated_text);
    } catch (error) {
      setError(\`Translation failed: \${error.message}\`);
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <ThemeProvider>
      <View padding="2rem">
        <Heading level={1}>NVIDIA NIM Translation Demo</Heading>
        
        {error && (
          <Alert variation="error" marginBottom="1rem">
            {error}
          </Alert>
        )}

        <TextAreaField
          label="Enter text to translate"
          rows={4}
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder="Enter text to translate"
          marginBottom="1rem"
        />

        <Button
          onClick={handleTranslate}
          isLoading={loading}
          loadingText="Translating..."
          variation="primary"
          marginBottom="1rem"
        >
          Translate
        </Button>

        {translatedText && (
          <View>
            <Heading level={2}>Translated Text:</Heading>
            <View
              backgroundColor="var(--amplify-colors-background-secondary)"
              padding="1rem"
              borderRadius="medium"
            >
              {translatedText}
            </View>
          </View>
        )}
      </View>
    </ThemeProvider>
  );
}

export default App;
EOL

# Create a basic test file
cat > src/App.test.js << EOL
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders NIM translation demo heading', () => {
  render(<App />);
  const headingElement = screen.getByText(/NVIDIA NIM Translation Demo/i);
  expect(headingElement).toBeInTheDocument();
});
EOL

# Initialize Amplify
echo -e "${BLUE}Initializing Amplify...${NC}"
amplify init --yes

# Add authentication (optional)
echo -e "${BLUE}Would you like to add authentication? (y/n)${NC}"
read -r ADD_AUTH
if [[ $ADD_AUTH =~ ^[Yy]$ ]]; then
    amplify add auth
    amplify push --yes
fi

# Create start script
cat > start-demo.sh << EOL
#!/bin/bash
echo "Starting NIM Demo..."
npm start
EOL

chmod +x start-demo.sh

# Final setup steps
echo -e "${GREEN}Setup complete! To start the demo:${NC}"
echo -e "1. cd ${PROJECT_NAME}"
echo -e "2. Update the .env file with your NIM API endpoint and key"
echo -e "3. Run './start-demo.sh' or 'npm start'"

# Install additional dependencies if needed
npm install

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}You can now start the application by running:${NC}"
echo -e "./start-demo.sh" 