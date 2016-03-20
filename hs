#!/usr/bin/env python3

import argparse
import os

def here_script(directory, command):
	print("here_script(", directory, command, ")")

def available_scripts(directory, format):
	print("available_scripts(", directory, format, ")")


# -w --what prints the available commands in different formats
# -C changes the target directory from the default, which is the current working directory

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description='Quickly launch scripts here.')
	parser.add_argument('-C', nargs='?', default=os.getcwd(), dest='directory', help='Run as if in DIRECTORY.')
	group = parser.add_mutually_exclusive_group(required=False)
	group.add_argument('-w', '--what', nargs='?', choices=['pretty', 'oneline', 'raw'], const='pretty', help="Run no command and print available commands for the directory instead. Defaults to 'pretty'.")
	group.add_argument('command', nargs='?', default='default')
	args = parser.parse_args()

	if args.what != None:
		available_scripts(args.directory, args.what)
	elif args.command != None:
		here_script(args.directory, args.command)
