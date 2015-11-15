# 開発者用ドキュメント(補足)

## ソースコードについて

本アプリケーションはフリーソフトウエアです。作者によるソフトウエアコードはMITライセンスに準拠します(See [LICENCE.txt](LICENCE.txt))。

* [MIT Licence (参考和訳)](http://sourceforge.jp/projects/opensource/wiki/licenses%2FMIT_license)

本アプリケーションは[Google Maps API][]を利用しています。Googleのライセンス方針は次をご覧下さい。

* [Google Maps APIのライセンス](https://developers.google.com/maps/licensing?hl=ja)

本ソフトウエアのソースコードとデータをgithubで公開します(本リポジトリ)。次のJavaScriptライブラリを利用しています。

* [jQuery][]
* [jQuery Mousewheel][]
* [Modernizr][]

コードは[CoffeeScript][]で記述しており、コンパイルには[node.js][]の環境が必要です。またHTML生成は[Haml][]、CSS生成は[Sass][]、ファイル生成管理は[Rake][]を用いています。これらは[Ruby] 1.9以上の環境で動作します。

サーバサイドのコードはnode.jsで書かれています。

[CoffeeScript]: http://coffeescript.org/ "CoffeeScript"
[Google Maps API]: https://developers.google.com/maps/?hl=ja "Google Maps API"
[Haml]: http://haml.info/ "Haml (HTML abstraction markup language)"
[jQuery]: http://jquery.com/ "jQuery"
[jQuery Mousewheel]: http://plugins.jquery.com/mousewheel/ "jQuery Mousewheel"
[Modernizr]: http://modernizr.com/ "Modernizr"
[node.js]: http://nodejs.org/ "node.js"
[Rake]: http://rake.rubyforge.org/ "Rake - Ruby Make"
[Ruby]: http://www.ruby-lang.org/ "Ruby Programming Language"
[Sass]: http://sass-lang.com/ "Sass: Syntactically Awesome Style Sheets"

## データについて

本アプリケーションのデータは気象庁ホームページの「過去の気象データ検索」から取得した1時間ごとの値です。

* [過去の気象データ検索](http://www.data.jma.go.jp/obd/stats/etrn/index.php "過去の気象データ検索")

データの著作権は気象庁の方針に従います。気象庁ホームページ掲載情報の著作権については次をご覧下さい。

* [著作権・リンク・個人情報保護について](http://www.jma.go.jp/jma/kishou/info/coment.html)

本リポジトリには動作確認用に2014年(365日分)のデータが付属しており(`/public/data`)、そのままローカルサーバとして起動できます。node.jsが動作する環境で`web.js`を実行すればサーバが立ち上がります。

全データは次のURLからtar.gzアーカイブとして取得できます。

> <http://higuma.boo.jp/tenki-data-map-files/data/>

## 作者

宮根 裕司 (<myuj1964@gmail.com>)
