from action import Action
import functools
import os
import yaml

rule_dir = os.path.expanduser("~/.config/here-script/rules/")

def init_rule_dir():
	os.makedirs(rule_dir)

class Rulebook:
	def __init__(self, yaml_object):
		self.yaml_rules = yaml_object['rules']
		self.yaml_actions = yaml_object['actions']
		self.rules_test = test_from_rules(self.yaml_rules)
		self.actions = list(map(lambda y: Action(y), self.yaml_actions))

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

def yaml_from_file(path):
	file = open(path, 'r')
	y = yaml.load(file)
	file.close()
	return y

def from_yaml(yaml_object):
	return Rulebook(yaml_object)

def get_files(directory=rule_dir):
	if os.path.exists(directory):
		files = map(lambda f: os.path.join(directory, f), os.listdir(directory))
		return filter(lambda f: os.path.isfile(f), files)
	else:
		try:
			init_rule_dir()
			return get_files(directory)
		except OSError as e:
			raise

def get_rulebooks(directory=rule_dir):
	files = get_files(directory)
	objects = map(yaml_from_file, files)
	rulebooks = map(from_yaml, objects)
	return rulebooks
