@echo off
REM Create a virtual environment
python -m venv venv

REM Activate the virtual environment
call venv\Scripts\activate

REM Update pip before installing packages
python -m pip install --upgrade pip

REM Create requirements.txt and add needed packages
echo pynput>requirements.txt
echo requests>>requirements.txt
echo pyinstaller>>requirements.txt

REM Install all packages from requirements.txt
pip install -r requirements.txt

REM Wait for user before closing the window
pause
