#!/usr/bin/env python3

import argparse
import os
import yaml

rule_dir = os.path.expanduser("~/.config/here-script/rules/")

def init_rule_dir():
	os.makedirs(rule_dir)

def get_definition_files(directory=rule_dir):
	if os.path.exists(directory):
		files = map(lambda f: os.path.join(directory, f), os.listdir(directory))
		return filter(lambda f: os.path.isfile(f), files)
	else:
		try:
			init_rule_dir()
			return get_definition_files(directory)
		except OSError as e:
			raise

def get_definitions(directory=rule_dir):
	files = get_definition_files(directory)
	objects = map(lambda f: yaml_from_file(f), files)
	objects = list(objects)
	return objects

def yaml_from_file(path):
	file = open(path, 'r')
	y = yaml.load(file)
	file.close()
	return y

def here_script(directory, definitions, command):
	print("here_script(", directory, definitions, command, ")")

def available_scripts(directory, definitions, format):
	print("available_scripts(", directory, definitions, format, ")")


# -w --what prints the available commands in different formats
# -C changes the target directory from the default, which is the current working directory

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description='Quickly launch scripts here.')
	parser.add_argument('-C', nargs='?', default=os.getcwd(), dest='directory', help='Run as if in DIRECTORY.')
	group = parser.add_mutually_exclusive_group(required=False)
	group.add_argument('-w', '--what', nargs='?', choices=['pretty', 'oneline', 'raw'], const='pretty', help="Run no command and print available commands for the directory instead. Defaults to 'pretty'.")
	group.add_argument('command', nargs='?', default='default')
	args = parser.parse_args()

	definitions = get_definitions()

	if args.what != None:
		available_scripts(args.directory, definitions, args.what)
	elif args.command != None:
		here_script(args.directory, definitions, args.command)
