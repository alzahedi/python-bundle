import sys
import os
import yaml
import argparse
import platform
from scheduler import app

def load_config(config_file):
    with open(config_file, 'r') as f:
        return yaml.safe_load(f)

def modify_test_yaml_file(yaml_path):
    config = load_config(yaml_path)
    
    if platform.system() == 'Windows':
        bundled_python_path = os.path.join(os.path.dirname(__file__), 'windows', 'python3', 'python.exe')
    elif platform.system() == 'Linux':
        bundled_python_path = os.path.join(os.path.dirname(__file__), 'linux', 'python3', 'bin', 'python3')
    else:
        # Fallback for macOS or other systems
        bundled_python_path = 'python'

    # Modify all Command entries to use .exe instead of python
    for task in config.get('tasks', []):
        if 'Command' in task:
            # Replace "python run_tests.py" with path to run_tests.exe
            cmd = task['Command']
            if cmd.startswith('python run_tests.py'):
                cmd = cmd.replace('python', f'{bundled_python_path}', 1)
                task['Command'] = cmd
        
        #Also update RunCommandOnTimeout if it exists
        if 'RunCommandOnTimeout' in task:
            timeout_cmd = task['RunCommandOnTimeout']
            if timeout_cmd.startswith('python timeout_handler.py'):
                timeout_cmd = timeout_cmd.replace('python', f'{bundled_python_path}', 1)
                task['RunCommandOnTimeout'] = timeout_cmd
        
    # Write modified config to a temp file
    output_yaml = os.path.join(os.path.dirname(yaml_path), 'modified_test_scheduling.yaml')
    with open(output_yaml, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False, width=float('inf'))
    
    print(f"Modified YAML for exe execution: {output_yaml}")
    return output_yaml
        
        
def main():
    parser = argparse.ArgumentParser(description='Test Runner')
    parser.add_argument('--config', '-c',
                        default='config.yaml',
                        help='Path to config file (default: config.yaml)')

    args = parser.parse_args()

    try:
        print(f"Loading config from '{args.config}'")
        config = load_config(args.config)

        print("Setting environment variables...")
        for key, value in config.get('environment', {}).items():
            os.environ[key] = str(value)

        print("Starting test execution via Scheduler...")
        yaml_filename = "test_scheduling.yaml"
        final_yaml_file = modify_test_yaml_file(yaml_filename)
        print(f"Using scheduling file at '{final_yaml_file}'")

        try:
            app.run(final_yaml_file)
        except Exception as ex:
            print(f"Failure occurred during scheduler run - {ex}")
            sys.exit(1)

    except FileNotFoundError:
        print(f"Config file '{args.config}' not found!")
        sys.exit(1)


if __name__ == "__main__":
   main()