enum Model {
  green("Models.scnassets/green.usdc"),
  yellow("Models.scnassets/yellow.usdc"),
  red("Models.scnassets/red.usdc");

  final String path;

  const Model(this.path);

  Model next() {
    switch(this) {
      case Model.green:
        return Model.yellow;
      case Model.yellow:
        return Model.red;
      case Model.red:
        return Model.green;
    }
  }
}