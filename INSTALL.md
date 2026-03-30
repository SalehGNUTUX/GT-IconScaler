# Installation Instructions for GT-IconScaler

## Prerequisites
Before you begin, ensure you have the following installed:
- Git
- Node.js (version 14 or higher)
- npm (Node Package Manager)

## 1. Clone the Repository
Open your terminal and run the following command to clone the repository:

```bash
git clone https://github.com/SalehGNUTUX/GT-IconScaler.git
```

## 2. Navigate to the Directory
Change your directory to the cloned repository:

```bash
cd GT-IconScaler
```

## 3. Install Dependencies
Run the following command to install the necessary dependencies:

```bash
npm install
```

## 4. Run the Application
After the installation of dependencies is complete, start the application with:

```bash
npm start
```

## Troubleshooting Guide
### Common Issues
#### 1. Installation Failures
- **Problem:** `npm install` fails.  
  **Solution:** Check your Node.js version (it should be 14 or higher). The command to check is:
  ```bash
  node -v
  ```

#### 2. Application not starting
- **Problem:** After running `npm start`, the application does not launch.  
  **Solution:** Check for error messages in the terminal. Ensure you have all dependencies installed by rerunning `npm install`.

#### 3. Permission Denied Errors
- **Problem:** You might encounter permission errors while installing or running the application.  
  **Solution:** Try using `sudo` with your install command:
  ```bash
  sudo npm install
  ```
  Alternatively, you can fix directory permissions for npm:
  ```bash
  npm config set prefix ~/npm
  export PATH=$HOME/npm/bin:$PATH
  ```

#### 4. Running Outdated Packages
- **Problem:** Some packages might be outdated.  
  **Solution:** Update the packages by running:
  ```bash
  npm update
  ```

## Conclusion
You should now have GT-IconScaler installed and running on your system. If you encounter further issues, please check the repository's Issues section or reach out for help.