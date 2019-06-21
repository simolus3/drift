// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps
class Category extends DataClass {
  final int id;
  final String description;
  Category({this.id, this.description});
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
  int get hashCode => $mrjf($mrjc($mrjc(0, id.hashCode), description.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Category && other.id == id && other.description == description);
}

class CategoriesCompanion implements UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> description;
  const CategoriesCompanion({
    this.id = Value.absent(),
    this.description = Value.absent(),
  });
  @override
  bool isValuePresent(int index) {
    switch (index) {
      case 0:
        return id.present;
      case 1:
        return description.present;
      default:
        throw ArgumentError(
            'Hit an invalid state while serializing data. Did you run the build step?');
    }
    ;
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
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
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
  VerificationContext validateIntegrity(Category instance, bool isInserting) =>
      VerificationContext()
        ..handle(
            _idMeta, id.isAcceptableValue(instance.id, isInserting, _idMeta))
        ..handle(
            _descriptionMeta,
            description.isAcceptableValue(
                instance.description, isInserting, _descriptionMeta));
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Category.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(Category d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.id != null || includeNulls) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.description != null || includeNulls) {
      map['description'] = Variable<String, StringType>(d.description);
    }
    return map;
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(_db, alias);
  }
}

class Recipe extends DataClass {
  final int id;
  final String title;
  final String instructions;
  final int category;
  Recipe({this.id, this.title, this.instructions, this.category});
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
  int get hashCode => $mrjf($mrjc(
      $mrjc(
          $mrjc($mrjc(0, id.hashCode), title.hashCode), instructions.hashCode),
      category.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == id &&
          other.title == title &&
          other.instructions == instructions &&
          other.category == category);
}

class RecipesCompanion implements UpdateCompanion<Recipe> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> instructions;
  final Value<int> category;
  const RecipesCompanion({
    this.id = Value.absent(),
    this.title = Value.absent(),
    this.instructions = Value.absent(),
    this.category = Value.absent(),
  });
  @override
  bool isValuePresent(int index) {
    switch (index) {
      case 0:
        return id.present;
      case 1:
        return title.present;
      case 2:
        return instructions.present;
      case 3:
        return category.present;
      default:
        throw ArgumentError(
            'Hit an invalid state while serializing data. Did you run the build step?');
    }
    ;
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
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
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
  VerificationContext validateIntegrity(Recipe instance, bool isInserting) =>
      VerificationContext()
        ..handle(
            _idMeta, id.isAcceptableValue(instance.id, isInserting, _idMeta))
        ..handle(_titleMeta,
            title.isAcceptableValue(instance.title, isInserting, _titleMeta))
        ..handle(
            _instructionsMeta,
            instructions.isAcceptableValue(
                instance.instructions, isInserting, _instructionsMeta))
        ..handle(
            _categoryMeta,
            category.isAcceptableValue(
                instance.category, isInserting, _categoryMeta));
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Recipe.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(Recipe d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.id != null || includeNulls) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.title != null || includeNulls) {
      map['title'] = Variable<String, StringType>(d.title);
    }
    if (d.instructions != null || includeNulls) {
      map['instructions'] = Variable<String, StringType>(d.instructions);
    }
    if (d.category != null || includeNulls) {
      map['category'] = Variable<int, IntType>(d.category);
    }
    return map;
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(_db, alias);
  }
}

class Ingredient extends DataClass {
  final int id;
  final String name;
  final int caloriesPer100g;
  Ingredient({this.id, this.name, this.caloriesPer100g});
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
  int get hashCode => $mrjf($mrjc(
      $mrjc($mrjc(0, id.hashCode), name.hashCode), caloriesPer100g.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == id &&
          other.name == name &&
          other.caloriesPer100g == caloriesPer100g);
}

class IngredientsCompanion implements UpdateCompanion<Ingredient> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> caloriesPer100g;
  const IngredientsCompanion({
    this.id = Value.absent(),
    this.name = Value.absent(),
    this.caloriesPer100g = Value.absent(),
  });
  @override
  bool isValuePresent(int index) {
    switch (index) {
      case 0:
        return id.present;
      case 1:
        return name.present;
      case 2:
        return caloriesPer100g.present;
      default:
        throw ArgumentError(
            'Hit an invalid state while serializing data. Did you run the build step?');
    }
    ;
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
    return GeneratedIntColumn('id', $tableName, false, hasAutoIncrement: true);
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
  VerificationContext validateIntegrity(
          Ingredient instance, bool isInserting) =>
      VerificationContext()
        ..handle(
            _idMeta, id.isAcceptableValue(instance.id, isInserting, _idMeta))
        ..handle(_nameMeta,
            name.isAcceptableValue(instance.name, isInserting, _nameMeta))
        ..handle(
            _caloriesPer100gMeta,
            caloriesPer100g.isAcceptableValue(
                instance.caloriesPer100g, isInserting, _caloriesPer100gMeta));
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Ingredient.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(Ingredient d, {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.id != null || includeNulls) {
      map['id'] = Variable<int, IntType>(d.id);
    }
    if (d.name != null || includeNulls) {
      map['name'] = Variable<String, StringType>(d.name);
    }
    if (d.caloriesPer100g != null || includeNulls) {
      map['calories'] = Variable<int, IntType>(d.caloriesPer100g);
    }
    return map;
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(_db, alias);
  }
}

class IngredientInRecipe extends DataClass {
  final int recipe;
  final int ingredient;
  final int amountInGrams;
  IngredientInRecipe({this.recipe, this.ingredient, this.amountInGrams});
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
      $mrjc($mrjc(0, recipe.hashCode), ingredient.hashCode),
      amountInGrams.hashCode));
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is IngredientInRecipe &&
          other.recipe == recipe &&
          other.ingredient == ingredient &&
          other.amountInGrams == amountInGrams);
}

class IngredientInRecipesCompanion
    implements UpdateCompanion<IngredientInRecipe> {
  final Value<int> recipe;
  final Value<int> ingredient;
  final Value<int> amountInGrams;
  const IngredientInRecipesCompanion({
    this.recipe = Value.absent(),
    this.ingredient = Value.absent(),
    this.amountInGrams = Value.absent(),
  });
  @override
  bool isValuePresent(int index) {
    switch (index) {
      case 0:
        return recipe.present;
      case 1:
        return ingredient.present;
      case 2:
        return amountInGrams.present;
      default:
        throw ArgumentError(
            'Hit an invalid state while serializing data. Did you run the build step?');
    }
    ;
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
  VerificationContext validateIntegrity(
          IngredientInRecipe instance, bool isInserting) =>
      VerificationContext()
        ..handle(_recipeMeta,
            recipe.isAcceptableValue(instance.recipe, isInserting, _recipeMeta))
        ..handle(
            _ingredientMeta,
            ingredient.isAcceptableValue(
                instance.ingredient, isInserting, _ingredientMeta))
        ..handle(
            _amountInGramsMeta,
            amountInGrams.isAcceptableValue(
                instance.amountInGrams, isInserting, _amountInGramsMeta));
  @override
  Set<GeneratedColumn> get $primaryKey => {recipe, ingredient};
  @override
  IngredientInRecipe map(Map<String, dynamic> data, {String tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return IngredientInRecipe.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  Map<String, Variable> entityToSql(IngredientInRecipe d,
      {bool includeNulls = false}) {
    final map = <String, Variable>{};
    if (d.recipe != null || includeNulls) {
      map['recipe'] = Variable<int, IntType>(d.recipe);
    }
    if (d.ingredient != null || includeNulls) {
      map['ingredient'] = Variable<int, IntType>(d.ingredient);
    }
    if (d.amountInGrams != null || includeNulls) {
      map['amount'] = Variable<int, IntType>(d.amountInGrams);
    }
    return map;
  }

  @override
  $IngredientInRecipesTable createAlias(String alias) {
    return $IngredientInRecipesTable(_db, alias);
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  $CategoriesTable _categories;
  $CategoriesTable get categories => _categories ??= $CategoriesTable(this);
  $RecipesTable _recipes;
  $RecipesTable get recipes => _recipes ??= $RecipesTable(this);
  $IngredientsTable _ingredients;
  $IngredientsTable get ingredients => _ingredients ??= $IngredientsTable(this);
  $IngredientInRecipesTable _ingredientInRecipes;
  $IngredientInRecipesTable get ingredientInRecipes =>
      _ingredientInRecipes ??= $IngredientInRecipesTable(this);
  @override
  List<TableInfo> get allTables =>
      [categories, recipes, ingredients, ingredientInRecipes];
}
