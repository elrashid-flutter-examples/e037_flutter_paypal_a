import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

var clientId;
var clientSecret;

String apiEndpoint1 = "https://api.sandbox.paypal.com/v1/oauth2/token";
String apiEndpoint2 = "https://api.sandbox.paypal.com/v1/payments/payment";

Future main(List<String> arguments) async {
  var jsonData = json.decode(await File("secret.json").readAsString());
  clientId =jsonData["clientId"];
  clientSecret =jsonData["clientSecret"];
  print(arguments);
  if (arguments.length == 0) {
    print("step 1 ");
    step1();
  } else if (arguments.length == 2) {
    print("step 2 ");
    String executeUrl = arguments[0];
    String callbackUrl = arguments[1];
    step2(executeUrl, callbackUrl);
  }
}


step1() async {
  var basicAuth =
      'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret'));
  var formHeader = "application/x-www-form-urlencoded";

  var headers1 = Map<String, String>();
  headers1['Accept'] = "application/json";
  headers1['Accept-Language'] = "en_US";
  headers1['content-type'] = "application/json";
  headers1['authorization'] = basicAuth;
  headers1['content-type'] = formHeader;
  String data1 = "grant_type=client_credentials";

  var response1 = await http.post(
    apiEndpoint1,
    body: data1,
    headers: headers1,
  );
  File("output/step.1.1.json").writeAsString(response1.body);
  // print(response1.body);
  var jsonOpj1 = jsonDecode(response1.body);
  var accessToken = jsonOpj1['access_token'];

  var headers2 = Map<String, String>();
  headers2['Content-Type'] = "application/json";
  headers2['authorization'] = "Bearer $accessToken";
  var body = json.encode(payment1);

  File("output/step.1.2.json").writeAsString(body);

  var response2 = await http.post(
    apiEndpoint2,
    body: body,
    headers: headers2,
  );

  File("output/step.1.3.json").writeAsString(response2.body);
  // print(response2.body);

  String redirectHref;
  String executeHref;
  var jsonOpj2 = jsonDecode(response2.body);
  var links = jsonOpj2['links'];
  print("-----------------------------------------");
  links.forEach((link) {
    var href = link["href"];
    var rel = link["rel"];
    var method = link["method"];
    print(href);
    print(rel);
    print(method);
    print("-----------------------------------------");
    if (rel == "approval_url") redirectHref = href;
    if (rel == "execute") executeHref = href;
  });

  print('will REDIRECT to :');
  print('$redirectHref');

  print(
      'after REDIRECT abd login use callbackUrl abd  execute url like this :');
  print('dart main.dart "execute Url" "callbackUrl from the browser"');
  print('dart main.dart "$executeHref" "past here"');
  Process.run("start", [redirectHref.replaceAll("&", "^&")], runInShell: true);
}

step2(String executeUrl, String callbackUrl) async {
  print("executeUrl => $executeUrl");
  print("callbackUrl => $callbackUrl");
  var responceParts = callbackUrl.toString().split("?")[1].split("&");
  var payerID = responceParts.singleWhere(
    (part) => part.startsWith('PayerID='),
    orElse: () => null,
  );
  if (payerID != null) payerID = payerID.replaceFirst('PayerID=', '');

  print("payerID => $payerID");

  var basicAuth =
      'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret'));
  var formHeader = "application/x-www-form-urlencoded";

  var headers1 = Map<String, String>();
  headers1['Accept'] = "application/json";
  headers1['Accept-Language'] = "en_US";
  headers1['content-type'] = "application/json";
  headers1['authorization'] = basicAuth;
  headers1['content-type'] = formHeader;
  String data1 = "grant_type=client_credentials";

  var response1 = await http.post(
    apiEndpoint1,
    body: data1,
    headers: headers1,
  );
  File("output/step.2.1.json").writeAsString(response1.body);
  // print(response1.body);
  var jsonOpj1 = jsonDecode(response1.body);
  var accessToken = jsonOpj1['access_token'];

  var headers2 = Map<String, String>();
  headers2['Content-Type'] = "application/json";
  headers2['authorization'] = "Bearer $accessToken";
  var body = json.encode({"payer_id": "$payerID"});

  var response2 = await http.post(
    executeUrl,
    body: body,
    headers: headers2,
  );
  File("output/step.2.2.json").writeAsString(response2.body);
  // print(response2.body);
}

final payment1 = Payment(
  intent: "sale",
  payer: Payer(
    paymentMethod: "paypal",
  ),
  transactions: <Transaction>[
    Transaction(
      amount: Amount(
        total: "30.11",
        currency: "USD",
        details: Details(
            subtotal: "30.00",
            tax: "0.07",
            shipping: "0.03",
            handlingFee: "1.00",
            shippingDiscount: "-1.00",
            insurance: "0.01"),
      ),
      description: "This is the payment transaction description.",
      custom: "EBAY_EMS_90048630024435",
      invoiceNumber: "48787589676",
      paymentOptions: PaymentOptions(
        allowedPaymentMethod: "INSTANT_FUNDING_SOURCE",
      ),
      softDescriptor: "ECHI5786786",
      itemList: ItemList(
        items: <Item>[
          Item(
            name: "hat",
            description: "Brown color hat",
            quantity: "5",
            price: "3",
            tax: "0.01",
            sku: "1",
            currency: "USD",
          ),
          Item(
            name: "handbag",
            description: "Black color hand bag",
            quantity: "1",
            price: "15",
            tax: "0.02",
            sku: "product34",
            currency: "USD",
          ),
        ],
        shippingAddress: ShippingAddress(
          recipientName: "Hello World",
          line1: "4thFloor",
          line2: "unit#34",
          city: "SAn Jose",
          countryCode: "US",
          postalCode: "95131",
          phone: "011862212345678",
          state: "CA",
        ),
      ),
    ),
  ],
  noteToPayer: "Contact us for any questions on your order.",
  redirectUrls: RedirectUrls(
    returnUrl: "https://example.com",
    cancelUrl: "https://example.com",
  ),
);

class Payment {
  String intent;
  Payer payer;
  List<Transaction> transactions;
  String noteToPayer;
  RedirectUrls redirectUrls;

  Payment(
      {this.intent,
      this.payer,
      this.transactions,
      this.noteToPayer,
      this.redirectUrls});

  Payment.fromJson(Map<String, dynamic> json) {
    intent = json['intent'];
    payer = json['payer'] != null ? new Payer.fromJson(json['payer']) : null;
    if (json['transactions'] != null) {
      transactions = new List<Transaction>();
      json['transactions'].forEach((v) {
        transactions.add(new Transaction.fromJson(v));
      });
    }
    noteToPayer = json['note_to_payer'];
    redirectUrls = json['redirect_urls'] != null
        ? new RedirectUrls.fromJson(json['redirect_urls'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['intent'] = this.intent;
    if (this.payer != null) {
      data['payer'] = this.payer.toJson();
    }
    if (this.transactions != null) {
      data['transactions'] = this.transactions.map((v) => v.toJson()).toList();
    }
    data['note_to_payer'] = this.noteToPayer;
    if (this.redirectUrls != null) {
      data['redirect_urls'] = this.redirectUrls.toJson();
    }
    return data;
  }
}

class Transaction {
  Amount amount;
  String description;
  String custom;
  String invoiceNumber;
  PaymentOptions paymentOptions;
  String softDescriptor;
  ItemList itemList;

  Transaction(
      {this.amount,
      this.description,
      this.custom,
      this.invoiceNumber,
      this.paymentOptions,
      this.softDescriptor,
      this.itemList});

  Transaction.fromJson(Map<String, dynamic> json) {
    amount =
        json['amount'] != null ? new Amount.fromJson(json['amount']) : null;
    description = json['description'];
    custom = json['custom'];
    invoiceNumber = json['invoice_number'];
    paymentOptions = json['payment_options'] != null
        ? new PaymentOptions.fromJson(json['payment_options'])
        : null;
    softDescriptor = json['soft_descriptor'];
    itemList = json['item_list'] != null
        ? new ItemList.fromJson(json['item_list'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.amount != null) {
      data['amount'] = this.amount.toJson();
    }
    data['description'] = this.description;
    data['custom'] = this.custom;
    data['invoice_number'] = this.invoiceNumber;
    if (this.paymentOptions != null) {
      data['payment_options'] = this.paymentOptions.toJson();
    }
    data['soft_descriptor'] = this.softDescriptor;
    if (this.itemList != null) {
      data['item_list'] = this.itemList.toJson();
    }
    return data;
  }
}

class Amount {
  String total;
  String currency;
  Details details;

  Amount({this.total, this.currency, this.details});

  Amount.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    currency = json['currency'];
    details =
        json['details'] != null ? new Details.fromJson(json['details']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['currency'] = this.currency;
    if (this.details != null) {
      data['details'] = this.details.toJson();
    }
    return data;
  }
}

class Details {
  String subtotal;
  String tax;
  String shipping;
  String handlingFee;
  String shippingDiscount;
  String insurance;

  Details(
      {this.subtotal,
      this.tax,
      this.shipping,
      this.handlingFee,
      this.shippingDiscount,
      this.insurance});

  Details.fromJson(Map<String, dynamic> json) {
    subtotal = json['subtotal'];
    tax = json['tax'];
    shipping = json['shipping'];
    handlingFee = json['handling_fee'];
    shippingDiscount = json['shipping_discount'];
    insurance = json['insurance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['subtotal'] = this.subtotal;
    data['tax'] = this.tax;
    data['shipping'] = this.shipping;
    data['handling_fee'] = this.handlingFee;
    data['shipping_discount'] = this.shippingDiscount;
    data['insurance'] = this.insurance;
    return data;
  }
}

class ItemList {
  List<Item> items;
  ShippingAddress shippingAddress;

  ItemList({this.items, this.shippingAddress});

  ItemList.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      items = new List<Item>();
      json['items'].forEach((v) {
        items.add(new Item.fromJson(v));
      });
    }
    shippingAddress = json['shipping_address'] != null
        ? new ShippingAddress.fromJson(json['shipping_address'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.items != null) {
      data['items'] = this.items.map((v) => v.toJson()).toList();
    }
    if (this.shippingAddress != null) {
      data['shipping_address'] = this.shippingAddress.toJson();
    }
    return data;
  }
}

class Item {
  String name;
  String description;
  String quantity;
  String price;
  String tax;
  String sku;
  String currency;

  Item(
      {this.name,
      this.description,
      this.quantity,
      this.price,
      this.tax,
      this.sku,
      this.currency});

  Item.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    quantity = json['quantity'];
    price = json['price'];
    tax = json['tax'];
    sku = json['sku'];
    currency = json['currency'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['description'] = this.description;
    data['quantity'] = this.quantity;
    data['price'] = this.price;
    data['tax'] = this.tax;
    data['sku'] = this.sku;
    data['currency'] = this.currency;
    return data;
  }
}

class ShippingAddress {
  String recipientName;
  String line1;
  String line2;
  String city;
  String countryCode;
  String postalCode;
  String phone;
  String state;

  ShippingAddress(
      {this.recipientName,
      this.line1,
      this.line2,
      this.city,
      this.countryCode,
      this.postalCode,
      this.phone,
      this.state});

  ShippingAddress.fromJson(Map<String, dynamic> json) {
    recipientName = json['recipient_name'];
    line1 = json['line1'];
    line2 = json['line2'];
    city = json['city'];
    countryCode = json['country_code'];
    postalCode = json['postal_code'];
    phone = json['phone'];
    state = json['state'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['recipient_name'] = this.recipientName;
    data['line1'] = this.line1;
    data['line2'] = this.line2;
    data['city'] = this.city;
    data['country_code'] = this.countryCode;
    data['postal_code'] = this.postalCode;
    data['phone'] = this.phone;
    data['state'] = this.state;
    return data;
  }
}

class Payer {
  String paymentMethod;

  Payer({this.paymentMethod});

  Payer.fromJson(Map<String, dynamic> json) {
    paymentMethod = json['payment_method'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['payment_method'] = this.paymentMethod;
    return data;
  }
}

class RedirectUrls {
  String returnUrl;
  String cancelUrl;

  RedirectUrls({this.returnUrl, this.cancelUrl});

  RedirectUrls.fromJson(Map<String, dynamic> json) {
    returnUrl = json['return_url'];
    cancelUrl = json['cancel_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['return_url'] = this.returnUrl;
    data['cancel_url'] = this.cancelUrl;
    return data;
  }
}

class PaymentOptions {
  String allowedPaymentMethod;

  PaymentOptions({this.allowedPaymentMethod});

  PaymentOptions.fromJson(Map<String, dynamic> json) {
    allowedPaymentMethod = json['allowed_payment_method'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['allowed_payment_method'] = this.allowedPaymentMethod;
    return data;
  }
}
