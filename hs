#!/usr/bin/env python3

import argparse
import os
import yaml
import functools

rule_dir = os.path.expanduser("~/.config/here-script/rules/")

class Definition:
	def __init__(self, yaml_object):
		self.yaml_rules = yaml_object['rules']
		self.yaml_actions = yaml_object['actions']
		self.rules_test = test_from_rules(self.yaml_rules)
		self.actions = list(map(lambda y: Action(y), self.yaml_actions))

class Action:
	def __init__(self, yaml_object):
		self.description = yaml_object['description']
		self.title = yaml_object['title']
		self.shell = yaml_object['shell']
		self.binding = yaml_object['binding']
		assert type(self.description) is str
		assert type(self.title) is str
		assert type(self.shell) is str
		assert type(self.binding) is str

	def __str__(self):
		return self.title
	
	def __repr__(self):
		return self.__str__()

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
		return result

	def path_rule(argument, directory):
		current = os.path.realpath(directory)
		rule_target = os.path.realpath(os.path.expanduser(argument))
		result = current.startswith(rule_target)
		return result

	def test_all_of(rules):
		return lambda d: all(map(lambda r: test_rule(r)(d), rules))

	def test_any_of(rules):
		return lambda d: any(map(lambda r: test_rule(r)(d), rules))

	return test_all_of(rules)

def incr_str(s):
	assert len(s) > 0
	head = s[:len(s) - 1]
	last = s[len(s) - 1]
	if last.isalpha() and last.upper() != 'Z':
		return head + chr(ord(last) + 1)
	elif last == 'Z':
		return head + 'a'
	elif last == 'z':
		return head + '0'
	elif last.isdigit() and last != '9':
		return head + chr(ord(last) + 1)
	else:
		return s + 'A'

def init_rule_dir():
	os.makedirs(rule_dir)

def binding_dict(actions_iterable):
	d = {}
	for action in actions_iterable:
		b = action.binding
		while b in d:
			b = incr_str(b)
		d[b] = action
	return d

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

def filter_matching_definitions(definitions, directory):
	return filter(lambda d: d.rules_test(directory), definitions)

def definition_from_yaml(yaml_object):
	return Definition(yaml_object)

def yaml_from_file(path):
	file = open(path, 'r')
	y = yaml.load(file)
	file.close()
	return y

def get_definitions(directory=rule_dir):
	files = get_definition_files(directory)
	objects = map(yaml_from_file, files)
	definitions = map(definition_from_yaml, objects)
	return definitions

def get_actions(definitions_iterable):
	actions = []
	for definition in definitions_iterable:
		actions += definition.actions
	return actions

def here_script(directory, definitions, command):
	active_definitions = filter_matching_definitions(definitions, directory)
	actions = get_actions(active_definitions)
	actions = binding_dict(actions)
	if command in actions:
		os.execl("/bin/sh", "sh", "-c", actions[command].shell)
	else:
		print('%s is undefined.' % command)

def available_scripts(directory, definitions, format):
	active_definitions = filter_matching_definitions(definitions, directory)
	actions = get_actions(active_definitions)
	actions = binding_dict(actions)

	if format == 'pretty':
		for binding, action in actions.items():
			print('\t%s\t%s' % (binding, action.description))
	elif format == 'oneline':
		parts = ['%s %s' % (binding, action.title) for binding, action in actions.items()]
		print(', '.join(parts))

# -w --what prints the available commands in different formats
# -C changes the target directory from the default, which is the current working directory

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description='Quickly launch scripts here.')
	parser.add_argument('-C', nargs='?', default=os.getcwd(), dest='directory', help='Run as if in DIRECTORY.')
	group = parser.add_mutually_exclusive_group(required=False)
	group.add_argument('-w', '--what', nargs='?', choices=['pretty', 'oneline'], const='pretty', help="Run no command and print available commands for the directory instead. Defaults to 'pretty'.")
	group.add_argument('command', nargs='?', default='default')
	args = parser.parse_args()

	definitions = get_definitions()

	if args.what != None:
		available_scripts(args.directory, definitions, args.what)
	elif args.command != None:
		here_script(args.directory, definitions, args.command)
