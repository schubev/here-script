#!/usr/bin/env python3

import argparse
import os
import yaml
import functools

rule_dir = os.path.expanduser("~/.config/here-script/rules/")

class Definition:
	def __init__(self, yaml_object):
		self.rules = yaml_object['rules']
		self.actions = yaml_object['actions']
		self.rules_test = test_from_rules(self.rules)

def test_from_rules(rules):
	def test_rule(rule):
		operators = {
			'contains': contains_rule,
			'path': path_rule
		}

		combinators = {
			'any': test_any_of,
			'all': test_all_of
		}

		if len(rule) == 1:
			keys = list(rule.keys())
			if len(keys) != 1:
				raise
			op = keys[0]
			args = rule[op]
			if op in operators:
				return functools.partial(operators[op], args)
			elif op in combinators:
				return combinators[op](args)
			else:
				raise

	def contains_rule(argument, directory):
		if argument.endswith('/'):
			result = any(map(lambda f: (f + '/') == argument and os.path.isdir('./' + f), os.listdir(directory)))
		else:
			result = any(map(lambda f: f == argument, os.listdir(directory)))
		print("CONTAINS", directory, argument, result)
		return result

	def path_rule(argument, directory):
		current = os.path.realpath(directory)
		rule_target = os.path.realpath(os.path.expanduser(argument))
		result = current.startswith(rule_target)
		print("PATH", current, rule_target, result)
		return result

	def test_all_of(rules):
		return lambda d: all(map(lambda r: test_rule(r)(d), rules))

	def test_any_of(rules):
		return lambda d: any(map(lambda r: test_rule(r)(d), rules))

	print("Building rule function for", rules)
	return test_all_of(rules)

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

def definition_from_yaml(yaml_object):
	return Definition(yaml_object)

def yaml_from_file(path):
	file = open(path, 'r')
	y = yaml.load(file)
	file.close()
	return y

def here_script(directory, definitions, command):
	# print("here_script(", directory, definitions, command, ")")
	for d in definitions:
		print(d.rules_test(directory))

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

	definitions = list(map(definition_from_yaml, get_definitions()))

	if args.what != None:
		available_scripts(args.directory, definitions, args.what)
	elif args.command != None:
		here_script(args.directory, definitions, args.command)
