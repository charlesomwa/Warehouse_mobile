import 'package:flutter/material.dart';
import 'package:warehouse_mobile/data/db_client.dart';
import 'package:warehouse_mobile/data/rest_ds.dart';
import 'package:warehouse_mobile/model/intent.dart';
import 'package:warehouse_mobile/model/product.dart';
import 'package:uuid/uuid.dart';
import 'package:warehouse_mobile/model/sync_err_msg.dart';
import 'package:warehouse_mobile/services/navigation_service.dart';

class _ProductData {
  String manufacturerName = '';
  String productModelName = '';
  num price = 0;
  String currency = '';
}

class NewProductState extends State<NewProduct> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  _ProductData _data = new _ProductData();

  RestDatasource api = new RestDatasource();
  DatabaseClient dbClient = new DatabaseClient();

  BuildContext _ctx;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    this._ctx = context;

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('New product'),
        ),
        body: Builder(builder: (BuildContext context) {
          this._ctx = context;
          return new Container(
              padding: new EdgeInsets.all(20.0),
              child: new Form(
                  key: this._formKey,
                  child: new ListView(children: <Widget>[
                    new TextFormField(
                      keyboardType: TextInputType.text,
                      decoration: new InputDecoration(
                          hintText: 'Samsung', labelText: 'Manufacturer'),
                      validator: this._validateName,
                      onSaved: (String value) {
                        this._data.manufacturerName = value;
                      },
                    ),
                    new TextFormField(
                        decoration: new InputDecoration(
                            hintText: 'S24F356FHUX',
                            labelText: 'Product model name'),
                        validator: this._validateName,
                        onSaved: (String value) {
                          this._data.productModelName = value;
                        }),
                    new TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            hintText: 'S24F356FHUX', labelText: 'Price'),
                        validator: this._validatePrice,
                        onSaved: (String value) {
                          this._data.price = double.parse(value);
                        }),
                    new TextFormField(
                        decoration: new InputDecoration(
                            hintText: 'PLN', labelText: 'Price currency'),
                        validator: this._validateName,
                        onSaved: (String value) {
                          this._data.currency = value;
                        }),
                    new Container(
                      width: screenSize.width,
                      child: new RaisedButton(
                        child: new Text(
                          'Add product',
                          style: new TextStyle(color: Colors.white),
                        ),
                        onPressed: _submit,
                        color: Colors.blue,
                      ),
                      margin: new EdgeInsets.only(top: 20.0),
                    )
                  ])));
        }));
  }

  void _submit() {
    final form = _formKey.currentState;

    if (form.validate()) {
      form.save();

      // temporary time based id
      var uuid = new Uuid().v1();

      Product newProduct = new Product(
          id: uuid,
          manufacturerName: this._data.manufacturerName,
          modelName: this._data.productModelName,
          price: this._data.price,
          currency: this._data.currency,
          localQuantity: 0,
          quantity: 0,
          intent: Intent.INSERT,
          modifiedAt: DateTime.now().toIso8601String(),
          syncProblem: SyncErrorMessage.empty());

      this.dbClient.insertProduct(newProduct).then((Product product) {
        Scaffold.of(_ctx).showSnackBar(
            new SnackBar(content: Text('Product added to local db!')));

        new NavigationService()
            .navigateTo(NavigationRoutes.PRODUCTS, this._ctx);
      }).catchError((dynamic error) {
        Scaffold.of(_ctx).showSnackBar(new SnackBar(
            content:
                Text('Product not added to local db...' + error.toString())));
      });
    }
  }

  String _validateName(String value) {
    if (value.length < 3) {
      return "Name should be at least 3 chars long";
    }

    return null;
  }

  String _validatePrice(String value) {
    try {
      num price = double.tryParse(value);

      if (price.isNegative) {
        return "Price should be positive";
      }
    } catch (exception) {
      return "Price should be entered in format like 1234.56";
    }
  }
}

class NewProduct extends StatefulWidget {
  @override
  NewProductState createState() => new NewProductState();
}
