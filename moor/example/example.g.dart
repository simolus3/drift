// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String description;
  Category({@required this.id, this.description});
  factory Category.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Category(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      description: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}description']),
    );
  }
  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Category(
      id: serializer.fromJson<int>(json['id']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'description': serializer.toJson<String>(description),
    };
  }

  @override
  CategoriesCompanion createCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  Category copyWith({int id, String description}) => Category(
        id: id ?? this.id,
        description: description ?? this.description,
      );
  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(id.hashCode, description.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.description == this.description);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> description;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
  });
  CategoriesCompanion copyWith({Value<int> id, Value<String> description}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  final GeneratedDatabase _db;
  final String _alias;
  $CategoriesTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  GeneratedTextColumn _description;
  @override
  GeneratedTextColumn get description =>
      _description ??= _constructDescription();
  GeneratedTextColumn _constructDescription() {
    return GeneratedTextColumn(
      'description',
      $tableName,
      true,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [id, description];
  @override
  $CategoriesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'categories';
  @override
  final String actualTableName = 'categories';
  @override
  VerificationContext validateIntegrity(CategoriesCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.description.present) {
      context.handle(_descriptionMeta,
          description.isAcceptableValue(d.description.value, _descriptionMeta));
    } else if (description.isRequired && isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Category.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(CategoriesCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.description.present) {
      map['description'] = Variable<String, StringType>(d.description.value);
    }
    return map;
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(_db, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final int id;
  final String title;
  final String instructions;
  final int category;
  Recipe(
      {@required this.id,
      @required this.title,
      @required this.instructions,
      this.category});
  factory Recipe.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Recipe(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      title:
          stringType.mapFromDatabaseResponse(data['${effectivePrefix}title']),
      instructions: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}instructions']),
      category:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}category']),
    );
  }
  factory Recipe.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Recipe(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      instructions: serializer.fromJson<String>(json['instructions']),
      category: serializer.fromJson<int>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'instructions': serializer.toJson<String>(instructions),
      'category': serializer.toJson<int>(category),
    };
  }

  @override
  RecipesCompanion createCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
    );
  }

  Recipe copyWith({int id, String title, String instructions, int category}) =>
      Recipe(
        id: id ?? this.id,
        title: title ?? this.title,
        instructions: instructions ?? this.instructions,
        category: category ?? this.category,
      );
  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('instructions: $instructions, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(id.hashCode,
      $mrjc(title.hashCode, $mrjc(instructions.hashCode, category.hashCode))));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.title == this.title &&
          other.instructions == this.instructions &&
          other.category == this.category);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> instructions;
  final Value<int> category;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.instructions = const Value.absent(),
    this.category = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    @required String title,
    @required String instructions,
    this.category = const Value.absent(),
  })  : title = Value(title),
        instructions = Value(instructions);
  RecipesCompanion copyWith(
      {Value<int> id,
      Value<String> title,
      Value<String> instructions,
      Value<int> category}) {
    return RecipesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      category: category ?? this.category,
    );
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  final GeneratedDatabase _db;
  final String _alias;
  $RecipesTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _titleMeta = const VerificationMeta('title');
  GeneratedTextColumn _title;
  @override
  GeneratedTextColumn get title => _title ??= _constructTitle();
  GeneratedTextColumn _constructTitle() {
    return GeneratedTextColumn('title', $tableName, false, maxTextLength: 16);
  }

  final VerificationMeta _instructionsMeta =
      const VerificationMeta('instructions');
  GeneratedTextColumn _instructions;
  @override
  GeneratedTextColumn get instructions =>
      _instructions ??= _constructInstructions();
  GeneratedTextColumn _constructInstructions() {
    return GeneratedTextColumn(
      'instructions',
      $tableName,
      false,
    );
  }

  final VerificationMeta _categoryMeta = const VerificationMeta('category');
  GeneratedIntColumn _category;
  @override
  GeneratedIntColumn get category => _category ??= _constructCategory();
  GeneratedIntColumn _constructCategory() {
    return GeneratedIntColumn(
      'category',
      $tableName,
      true,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [id, title, instructions, category];
  @override
  $RecipesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'recipes';
  @override
  final String actualTableName = 'recipes';
  @override
  VerificationContext validateIntegrity(RecipesCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.title.present) {
      context.handle(
          _titleMeta, title.isAcceptableValue(d.title.value, _titleMeta));
    } else if (title.isRequired && isInserting) {
      context.missing(_titleMeta);
    }
    if (d.instructions.present) {
      context.handle(
          _instructionsMeta,
          instructions.isAcceptableValue(
              d.instructions.value, _instructionsMeta));
    } else if (instructions.isRequired && isInserting) {
      context.missing(_instructionsMeta);
    }
    if (d.category.present) {
      context.handle(_categoryMeta,
          category.isAcceptableValue(d.category.value, _categoryMeta));
    } else if (category.isRequired && isInserting) {
      context.missing(_categoryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Recipe.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(RecipesCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.title.present) {
      map['title'] = Variable<String, StringType>(d.title.value);
    }
    if (d.instructions.present) {
      map['instructions'] = Variable<String, StringType>(d.instructions.value);
    }
    if (d.category.present) {
      map['category'] = Variable<int, IntType>(d.category.value);
    }
    return map;
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(_db, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final int id;
  final String name;
  final int caloriesPer100g;
  Ingredient(
      {@required this.id, @required this.name, @required this.caloriesPer100g});
  factory Ingredient.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Ingredient(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id']),
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name']),
      caloriesPer100g:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}calories']),
    );
  }
  factory Ingredient.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return Ingredient(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      caloriesPer100g: serializer.fromJson<int>(json['caloriesPer100g']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'caloriesPer100g': serializer.toJson<int>(caloriesPer100g),
    };
  }

  @override
  IngredientsCompanion createCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      caloriesPer100g: caloriesPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(caloriesPer100g),
    );
  }

  Ingredient copyWith({int id, String name, int caloriesPer100g}) => Ingredient(
        id: id ?? this.id,
        name: name ?? this.name,
        caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      );
  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('caloriesPer100g: $caloriesPer100g')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(id.hashCode, $mrjc(name.hashCode, caloriesPer100g.hashCode)));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.name == this.name &&
          other.caloriesPer100g == this.caloriesPer100g);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> caloriesPer100g;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.caloriesPer100g = const Value.absent(),
  });
  IngredientsCompanion.insert({
    this.id = const Value.absent(),
    @required String name,
    @required int caloriesPer100g,
  })  : name = Value(name),
        caloriesPer100g = Value(caloriesPer100g);
  IngredientsCompanion copyWith(
      {Value<int> id, Value<String> name, Value<int> caloriesPer100g}) {
    return IngredientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
    );
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  final GeneratedDatabase _db;
  final String _alias;
  $IngredientsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedIntColumn _id;
  @override
  GeneratedIntColumn get id => _id ??= _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  GeneratedTextColumn _name;
  @override
  GeneratedTextColumn get name => _name ??= _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn(
      'name',
      $tableName,
      false,
    );
  }

  final VerificationMeta _caloriesPer100gMeta =
      const VerificationMeta('caloriesPer100g');
  GeneratedIntColumn _caloriesPer100g;
  @override
  GeneratedIntColumn get caloriesPer100g =>
      _caloriesPer100g ??= _constructCaloriesPer100g();
  GeneratedIntColumn _constructCaloriesPer100g() {
    return GeneratedIntColumn(
      'calories',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [id, name, caloriesPer100g];
  @override
  $IngredientsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'ingredients';
  @override
  final String actualTableName = 'ingredients';
  @override
  VerificationContext validateIntegrity(IngredientsCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.id.present) {
      context.handle(_idMeta, id.isAcceptableValue(d.id.value, _idMeta));
    } else if (id.isRequired && isInserting) {
      context.missing(_idMeta);
    }
    if (d.name.present) {
      context.handle(
          _nameMeta, name.isAcceptableValue(d.name.value, _nameMeta));
    } else if (name.isRequired && isInserting) {
      context.missing(_nameMeta);
    }
    if (d.caloriesPer100g.present) {
      context.handle(
          _caloriesPer100gMeta,
          caloriesPer100g.isAcceptableValue(
              d.caloriesPer100g.value, _caloriesPer100gMeta));
    } else if (caloriesPer100g.isRequired && isInserting) {
      context.missing(_caloriesPer100gMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Ingredient.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(IngredientsCompanion d) {
    final map = <String, Variable>{};
    if (d.id.present) {
      map['id'] = Variable<int, IntType>(d.id.value);
    }
    if (d.name.present) {
      map['name'] = Variable<String, StringType>(d.name.value);
    }
    if (d.caloriesPer100g.present) {
      map['calories'] = Variable<int, IntType>(d.caloriesPer100g.value);
    }
    return map;
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(_db, alias);
  }
}

class IngredientInRecipe extends DataClass
    implements Insertable<IngredientInRecipe> {
  final int recipe;
  final int ingredient;
  final int amountInGrams;
  IngredientInRecipe(
      {@required this.recipe,
      @required this.ingredient,
      @required this.amountInGrams});
  factory IngredientInRecipe.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    return IngredientInRecipe(
      recipe: intType.mapFromDatabaseResponse(data['${effectivePrefix}recipe']),
      ingredient:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}ingredient']),
      amountInGrams:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}amount']),
    );
  }
  factory IngredientInRecipe.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return IngredientInRecipe(
      recipe: serializer.fromJson<int>(json['recipe']),
      ingredient: serializer.fromJson<int>(json['ingredient']),
      amountInGrams: serializer.fromJson<int>(json['amountInGrams']),
    );
  }
  @override
  Map<String, dynamic> toJson(
      {ValueSerializer serializer = const ValueSerializer.defaults()}) {
    return {
      'recipe': serializer.toJson<int>(recipe),
      'ingredient': serializer.toJson<int>(ingredient),
      'amountInGrams': serializer.toJson<int>(amountInGrams),
    };
  }

  @override
  IngredientInRecipesCompanion createCompanion(bool nullToAbsent) {
    return IngredientInRecipesCompanion(
      recipe:
          recipe == null && nullToAbsent ? const Value.absent() : Value(recipe),
      ingredient: ingredient == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredient),
      amountInGrams: amountInGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(amountInGrams),
    );
  }

  IngredientInRecipe copyWith(
          {int recipe, int ingredient, int amountInGrams}) =>
      IngredientInRecipe(
        recipe: recipe ?? this.recipe,
        ingredient: ingredient ?? this.ingredient,
        amountInGrams: amountInGrams ?? this.amountInGrams,
      );
  @override
  String toString() {
    return (StringBuffer('IngredientInRecipe(')
          ..write('recipe: $recipe, ')
          ..write('ingredient: $ingredient, ')
          ..write('amountInGrams: $amountInGrams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      recipe.hashCode, $mrjc(ingredient.hashCode, amountInGrams.hashCode)));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is IngredientInRecipe &&
          other.recipe == this.recipe &&
          other.ingredient == this.ingredient &&
          other.amountInGrams == this.amountInGrams);
}

class IngredientInRecipesCompanion extends UpdateCompanion<IngredientInRecipe> {
  final Value<int> recipe;
  final Value<int> ingredient;
  final Value<int> amountInGrams;
  const IngredientInRecipesCompanion({
    this.recipe = const Value.absent(),
    this.ingredient = const Value.absent(),
    this.amountInGrams = const Value.absent(),
  });
  IngredientInRecipesCompanion.insert({
    @required int recipe,
    @required int ingredient,
    @required int amountInGrams,
  })  : recipe = Value(recipe),
        ingredient = Value(ingredient),
        amountInGrams = Value(amountInGrams);
  IngredientInRecipesCompanion copyWith(
      {Value<int> recipe, Value<int> ingredient, Value<int> amountInGrams}) {
    return IngredientInRecipesCompanion(
      recipe: recipe ?? this.recipe,
      ingredient: ingredient ?? this.ingredient,
      amountInGrams: amountInGrams ?? this.amountInGrams,
    );
  }
}

class $IngredientInRecipesTable extends IngredientInRecipes
    with TableInfo<$IngredientInRecipesTable, IngredientInRecipe> {
  final GeneratedDatabase _db;
  final String _alias;
  $IngredientInRecipesTable(this._db, [this._alias]);
  final VerificationMeta _recipeMeta = const VerificationMeta('recipe');
  GeneratedIntColumn _recipe;
  @override
  GeneratedIntColumn get recipe => _recipe ??= _constructRecipe();
  GeneratedIntColumn _constructRecipe() {
    return GeneratedIntColumn(
      'recipe',
      $tableName,
      false,
    );
  }

  final VerificationMeta _ingredientMeta = const VerificationMeta('ingredient');
  GeneratedIntColumn _ingredient;
  @override
  GeneratedIntColumn get ingredient => _ingredient ??= _constructIngredient();
  GeneratedIntColumn _constructIngredient() {
    return GeneratedIntColumn(
      'ingredient',
      $tableName,
      false,
    );
  }

  final VerificationMeta _amountInGramsMeta =
      const VerificationMeta('amountInGrams');
  GeneratedIntColumn _amountInGrams;
  @override
  GeneratedIntColumn get amountInGrams =>
      _amountInGrams ??= _constructAmountInGrams();
  GeneratedIntColumn _constructAmountInGrams() {
    return GeneratedIntColumn(
      'amount',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [recipe, ingredient, amountInGrams];
  @override
  $IngredientInRecipesTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'recipe_ingredients';
  @override
  final String actualTableName = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(IngredientInRecipesCompanion d,
      {bool isInserting = false}) {
    final context = VerificationContext();
    if (d.recipe.present) {
      context.handle(
          _recipeMeta, recipe.isAcceptableValue(d.recipe.value, _recipeMeta));
    } else if (recipe.isRequired && isInserting) {
      context.missing(_recipeMeta);
    }
    if (d.ingredient.present) {
      context.handle(_ingredientMeta,
          ingredient.isAcceptableValue(d.ingredient.value, _ingredientMeta));
    } else if (ingredient.isRequired && isInserting) {
      context.missing(_ingredientMeta);
    }
    if (d.amountInGrams.present) {
      context.handle(
          _amountInGramsMeta,
          amountInGrams.isAcceptableValue(
              d.amountInGrams.value, _amountInGramsMeta));
    } else if (amountInGrams.isRequired && isInserting) {
      context.missing(_amountInGramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipe, ingredient};
  @override
  IngredientInRecipe map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return IngredientInRecipe.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(IngredientInRecipesCompanion d) {
    final map = <String, Variable>{};
    if (d.recipe.present) {
      map['recipe'] = Variable<int, IntType>(d.recipe.value);
    }
    if (d.ingredient.present) {
      map['ingredient'] = Variable<int, IntType>(d.ingredient.value);
    }
    if (d.amountInGrams.present) {
      map['amount'] = Variable<int, IntType>(d.amountInGrams.value);
    }
    return map;
  }

  @override
  $IngredientInRecipesTable createAlias(String alias) {
    return $IngredientInRecipesTable(_db, alias);
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  $CategoriesTable _categories;
  $CategoriesTable get categories => _categories ??= $CategoriesTable(this);
  $RecipesTable _recipes;
  $RecipesTable get recipes => _recipes ??= $RecipesTable(this);
  $IngredientsTable _ingredients;
  $IngredientsTable get ingredients => _ingredients ??= $IngredientsTable(this);
  $IngredientInRecipesTable _ingredientInRecipes;
  $IngredientInRecipesTable get ingredientInRecipes =>
      _ingredientInRecipes ??= $IngredientInRecipesTable(this);
  TotalWeightResult _rowToTotalWeightResult(QueryRow row) {
    return TotalWeightResult(
      title: row.readString('title'),
      totalWeight: row.readInt('total_weight'),
    );
  }

  Selectable<TotalWeightResult> _totalWeightQuery() {
    return customSelectQuery(
        'SELECT r.title, SUM(ir.amount) AS total_weight\n        FROM recipes r\n        INNER JOIN recipe_ingredients ir ON ir.recipe = r.id\n      GROUP BY r.id',
        variables: [],
        readsFrom: {recipes, ingredientInRecipes}).map(_rowToTotalWeightResult);
  }

  Future<List<TotalWeightResult>> _totalWeight() {
    return _totalWeightQuery().get();
  }

  Stream<List<TotalWeightResult>> _watchTotalWeight() {
    return _totalWeightQuery().watch();
  }

  @override
  List<TableInfo> get allTables =>
      [categories, recipes, ingredients, ingredientInRecipes];
  @override
  List<DatabaseSchemaEntity> get allEntities =>
      [categories, recipes, ingredients, ingredientInRecipes];
}

class TotalWeightResult {
  final String title;
  final int totalWeight;
  TotalWeightResult({
    this.title,
    this.totalWeight,
  });
  @override
  int get hashCode => $mrjf($mrjc(title.hashCode, totalWeight.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is TotalWeightResult &&
          other.title == this.title &&
          other.totalWeight == this.totalWeight);
}
