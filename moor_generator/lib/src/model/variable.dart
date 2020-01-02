import 'declarations/declaration.dart';

class MoorVariable implements HasDeclaration 
{
	final String type;
	final String name;
	final String value;

  	Declaration declaration;

	MoorVariable({
		this.type,
		this.name,
		this.value,
		this.declaration
	});

	@override
	String toString() => '$type $name${value == null ? "" : "= $value"}';
}