import os
import requests
import json

def main():
    # Read the .env file
    env_vars = {}
    try:
        with open('c:\\Users\\mmdig_q4f4o3g\\Documents\\Workspace\\task-flutter\\.env', 'r') as f:
            for line in f:
                if '=' in line:
                    k, v = line.strip().split('=', 1)
                    env_vars[k.strip()] = v.strip()
    except Exception as e:
        print("Error reading .env:", e)
        return

    api_key = env_vars.get('GEMINI_API_KEY')
    if not api_key:
        print("No GEMINI_API_KEY found.")
        return

    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    response = requests.get(url)
    
    if response.status_code == 200:
        models = response.json().get('models', [])
        print("Available models:")
        for m in models:
            name = m.get('name')
            if 'gemini' in name.lower():
                print(name)
    else:
        print(f"Error {response.status_code}: {response.text}")

if __name__ == '__main__':
    main()
