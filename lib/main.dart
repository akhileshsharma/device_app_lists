import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      home: ListAppsPages(),
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.tealAccent[200],
      ),
    ));

/// アプリ本体
class ListAppsPages extends StatefulWidget {
  @override
  _ListAppsPagesState createState() => _ListAppsPagesState();
}

/// アプリ本体のステート
class _ListAppsPagesState extends State<ListAppsPages> {
  /// ステート更新（画面再描画）のたびに「システムアプリを含めるかどうか」「起動できるアプリのみにするかどうか」が初期化されては困るので、
  /// フィールド宣言時に初期化している（ build メソッドはステート更新時に呼ばれてしまうため）
  bool _showSystemApps = true;
  bool _onlyLaunchableApps = true;

  @override
  Widget build(BuildContext context) {
    // アプリ本体を構成するウィジェット
    return Scaffold(
      appBar: AppBar(
        title: Text("Installed applications"),
        actions: <Widget>[
          // AppBar にボタンを用意して表示内容を切り替える処理が書かれている
          PopupMenuButton(
            itemBuilder: (context) {
              return <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                    value: 'system_apps', child: Text('Toggle system apps')),
                PopupMenuItem<String>(
                  value: "launchable_apps",
                  child: Text('Toggle launchable apps only'),
                )
              ];
            },
            onSelected: (key) {
              if (key == "system_apps") {
                // 「システムアプリを含めるかどうか」を切り替える
                setState(() {
                  _showSystemApps = !_showSystemApps;
                });
              }
              if (key == "launchable_apps") {
                // 「起動できるアプリのみにするかどうか」を切り替える
                setState(() {
                  _onlyLaunchableApps = !_onlyLaunchableApps;
                });
              }
            },
          )
        ],
      ),

      // アプリの一覧は非同期で取得する必要があるため別クラス（private）として切り出している
      body: _ListAppsPagesContent(
        includeSystemApps: _showSystemApps,
        onlyAppsWithLaunchIntent: _onlyLaunchableApps,
        key: GlobalKey(),
      ),
    );
  }
}

/// アプリの一覧を表示するウィジェット
///  実装は ListView
class _ListAppsPagesContent extends StatelessWidget {
  /// システムアプリを含めるかどうか
  final bool includeSystemApps;

  /// 起動できるアプリのみにするかどうか
  final bool onlyAppsWithLaunchIntent;

  /// コンストラクタ
  const _ListAppsPagesContent({
    Key key,
    this.includeSystemApps: false,
    this.onlyAppsWithLaunchIntent: false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// 非同期処理である `DeviceApps.getInstalledApplications` を利用するため、
    ///  `Future` （ JavaScript でいう Promise ）を扱うことができる `FutureBuilder` を利用している.
    ///  データ取得後は ListView として画面に表示される.
    return FutureBuilder(
      // `device_apps` パッケージを利用して端末にインストールされているアプリの一覧を取得している
      future: DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: includeSystemApps,
        onlyAppsWithLaunchIntent: onlyAppsWithLaunchIntent,
      ),
      builder: (context, data) {
        // 非同期処理中の判断
        if (data.data == null) {
          // データ取得前はローディング中のプログレスを表示
          return Center(
            child: const CircularProgressIndicator(),
          );
        } else {
          // データ取得後はリストビューに情報をセット
          final apps = data.data;
//          print(apps);

          return ListView.builder(
            itemBuilder: (context, position) {
              final app = apps[position];

              // アプリひとつずつ横並び（ Column ）で情報を表示する
              return Column(
                children: <Widget>[
                  ListTile(
                    // `x is AnyClass` という記述は Java でいう `x instanceOf AnyClass`
                    leading: app is ApplicationWithIcon
                        // アイコンを持っているアプリ（ ApplicationWithIcon インスタンス）の場合はアイコンを表示する
                        ? CircleAvatar(
                            backgroundImage: MemoryImage(app.icon),
                            backgroundColor: Colors.white,
                          )
                        // ない場合はアイコンなし
                        : null,

                    // リストをタップした場合は、そのアプリを起動する
                    onTap: () => DeviceApps.openApp(app.packageName),

                    // リストタイトルにアプリ名＋パッケージ名を表示
                    title: Text("${app.appName} (${app.packageName})"),

                    // リストサブタイトルにバージョンを表示
                    subtitle: Text('Version: ${app.versionName}'),
                  ),

                  // アンダーライン
                  Divider(
                    height: 1.0,
                  )
                ],
              );
            },
            itemCount: apps.length,
          );
        }
      },
    );
  }
}
