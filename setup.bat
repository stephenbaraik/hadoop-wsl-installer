@echo off
echo Making scripts executable and setting up Git repository...

REM Make scripts executable in WSL
wsl chmod +x install.sh
wsl chmod +x scripts/start-services.sh
wsl chmod +x scripts/stop-services.sh
wsl chmod +x scripts/test-installation.sh
wsl chmod +x scripts/status.sh
wsl chmod +x config/hadoop-env.sh

echo Scripts made executable.

REM Initialize Git repository
git init
git add .
git commit -m "Initial commit: Complete Hadoop WSL installer with robust configuration"

echo.
echo Git repository initialized and files committed.
echo.
echo =====================================================
echo HADOOP WSL INSTALLER SETUP COMPLETE!
echo =====================================================
echo.
echo To install Hadoop, run in WSL:
echo   ./install.sh
echo.
echo To manage services:
echo   ./scripts/start-services.sh    # Start all services
echo   ./scripts/stop-services.sh     # Stop all services  
echo   ./scripts/status.sh            # Check status
echo   ./scripts/test-installation.sh # Run tests
echo.
echo Web UIs will be available at:
echo   HDFS NameNode:      http://localhost:9870
echo   YARN ResourceManager: http://localhost:8088
echo   DataNode:           http://localhost:9864
echo   NodeManager:        http://localhost:8042
echo   JobHistory Server:  http://localhost:19888
echo.
echo To push to GitHub:
echo   1. Create a new repository on GitHub
echo   2. git remote add origin https://github.com/yourusername/hadoop-wsl-installer.git
echo   3. git push -u origin main
echo.
pause
