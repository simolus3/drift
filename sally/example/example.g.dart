// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// SallyGenerator
// **************************************************************************

class Category {
  final int id;
  final String description;
  Category({this.id, this.description});
  factory Category.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Category(
      id: intType.mapFromDatabaseResponse(data['id']),
      description: stringType.mapFromDatabaseResponse(data['description']),
    );
  }
  Category copyWith({int id, String description}) => Category(
        id: id ?? this.id,
        description: description ?? this.description,
      );
  @override
  int get hashCode => (id.hashCode) * 31 + description.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Category && other.id == id && other.description == description);
}

class $CategoriesTable extends Categories
    implements TableInfo<Categories, Category> {
  final GeneratedDatabase _db;
  $CategoriesTable(this._db);
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get description => GeneratedTextColumn(
        'description',
        true,
      );
  @override
  List<GeneratedColumn> get $columns => [id, description];
  @override
  Categories get asDslTable => this;
  @override
  String get $tableName => 'categories';
  @override
  bool validateIntegrity(Category instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      description.isAcceptableValue(instance.description, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data) {
    return Category.fromData(data, _db);
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
}

class Recipe {
  final int id;
  final String title;
  final String instructions;
  final int category;
  Recipe({this.id, this.title, this.instructions, this.category});
  factory Recipe.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Recipe(
      id: intType.mapFromDatabaseResponse(data['id']),
      title: stringType.mapFromDatabaseResponse(data['title']),
      instructions: stringType.mapFromDatabaseResponse(data['instructions']),
      category: intType.mapFromDatabaseResponse(data['category']),
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
  int get hashCode =>
      (((id.hashCode) * 31 + title.hashCode) * 31 + instructions.hashCode) *
          31 +
      category.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == id &&
          other.title == title &&
          other.instructions == instructions &&
          other.category == category);
}

class $RecipesTable extends Recipes implements TableInfo<Recipes, Recipe> {
  final GeneratedDatabase _db;
  $RecipesTable(this._db);
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get title =>
      GeneratedTextColumn('title', false, maxTextLength: 16);
  @override
  GeneratedTextColumn get instructions => GeneratedTextColumn(
        'instructions',
        false,
      );
  @override
  GeneratedIntColumn get category => GeneratedIntColumn(
        'category',
        true,
      );
  @override
  List<GeneratedColumn> get $columns => [id, title, instructions, category];
  @override
  Recipes get asDslTable => this;
  @override
  String get $tableName => 'recipes';
  @override
  bool validateIntegrity(Recipe instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      title.isAcceptableValue(instance.title, isInserting) &&
      instructions.isAcceptableValue(instance.instructions, isInserting) &&
      category.isAcceptableValue(instance.category, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data) {
    return Recipe.fromData(data, _db);
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
}

class Ingredient {
  final int id;
  final String name;
  final int caloriesPer100g;
  Ingredient({this.id, this.name, this.caloriesPer100g});
  factory Ingredient.fromData(Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Ingredient(
      id: intType.mapFromDatabaseResponse(data['id']),
      name: stringType.mapFromDatabaseResponse(data['name']),
      caloriesPer100g: intType.mapFromDatabaseResponse(data['calories']),
    );
  }
  Ingredient copyWith({int id, String name, int caloriesPer100g}) => Ingredient(
        id: id ?? this.id,
        name: name ?? this.name,
        caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      );
  @override
  int get hashCode =>
      ((id.hashCode) * 31 + name.hashCode) * 31 + caloriesPer100g.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == id &&
          other.name == name &&
          other.caloriesPer100g == caloriesPer100g);
}

class $IngredientsTable extends Ingredients
    implements TableInfo<Ingredients, Ingredient> {
  final GeneratedDatabase _db;
  $IngredientsTable(this._db);
  @override
  GeneratedIntColumn get id =>
      GeneratedIntColumn('id', false, hasAutoIncrement: true);
  @override
  GeneratedTextColumn get name => GeneratedTextColumn(
        'name',
        false,
      );
  @override
  GeneratedIntColumn get caloriesPer100g => GeneratedIntColumn(
        'calories',
        false,
      );
  @override
  List<GeneratedColumn> get $columns => [id, name, caloriesPer100g];
  @override
  Ingredients get asDslTable => this;
  @override
  String get $tableName => 'ingredients';
  @override
  bool validateIntegrity(Ingredient instance, bool isInserting) =>
      id.isAcceptableValue(instance.id, isInserting) &&
      name.isAcceptableValue(instance.name, isInserting) &&
      caloriesPer100g.isAcceptableValue(instance.caloriesPer100g, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data) {
    return Ingredient.fromData(data, _db);
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
}

class IngredientInRecipe {
  final int recipe;
  final int ingredient;
  final int amountInGrams;
  IngredientInRecipe({this.recipe, this.ingredient, this.amountInGrams});
  factory IngredientInRecipe.fromData(
      Map<String, dynamic> data, GeneratedDatabase db) {
    final intType = db.typeSystem.forDartType<int>();
    return IngredientInRecipe(
      recipe: intType.mapFromDatabaseResponse(data['recipe']),
      ingredient: intType.mapFromDatabaseResponse(data['ingredient']),
      amountInGrams: intType.mapFromDatabaseResponse(data['amount']),
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
  int get hashCode =>
      ((recipe.hashCode) * 31 + ingredient.hashCode) * 31 +
      amountInGrams.hashCode;
  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is IngredientInRecipe &&
          other.recipe == recipe &&
          other.ingredient == ingredient &&
          other.amountInGrams == amountInGrams);
}

class $IngredientInRecipesTable extends IngredientInRecipes
    implements TableInfo<IngredientInRecipes, IngredientInRecipe> {
  final GeneratedDatabase _db;
  $IngredientInRecipesTable(this._db);
  @override
  GeneratedIntColumn get recipe => GeneratedIntColumn(
        'recipe',
        false,
      );
  @override
  GeneratedIntColumn get ingredient => GeneratedIntColumn(
        'ingredient',
        false,
      );
  @override
  GeneratedIntColumn get amountInGrams => GeneratedIntColumn(
        'amount',
        false,
      );
  @override
  List<GeneratedColumn> get $columns => [recipe, ingredient, amountInGrams];
  @override
  IngredientInRecipes get asDslTable => this;
  @override
  String get $tableName => 'recipe_ingredients';
  @override
  bool validateIntegrity(IngredientInRecipe instance, bool isInserting) =>
      recipe.isAcceptableValue(instance.recipe, isInserting) &&
      ingredient.isAcceptableValue(instance.ingredient, isInserting) &&
      amountInGrams.isAcceptableValue(instance.amountInGrams, isInserting);
  @override
  Set<GeneratedColumn> get $primaryKey => {recipe, ingredient};
  @override
  IngredientInRecipe map(Map<String, dynamic> data) {
    return IngredientInRecipe.fromData(data, _db);
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
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(const SqlTypeSystem.withDefaults(), e);
  $CategoriesTable get categories => $CategoriesTable(this);
  $RecipesTable get recipes => $RecipesTable(this);
  $IngredientsTable get ingredients => $IngredientsTable(this);
  $IngredientInRecipesTable get ingredientInRecipes =>
      $IngredientInRecipesTable(this);
  @override
  List<TableInfo> get allTables =>
      [categories, recipes, ingredients, ingredientInRecipes];
}
