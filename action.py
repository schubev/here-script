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
