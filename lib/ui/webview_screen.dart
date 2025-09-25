import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final List<_TabData> _tabs = <_TabData>[];
  int _current = 0;
  final TextEditingController _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    _createTab(initialUrl: widget.url, makeCurrent: true);
  }

  _TabData get _tab => _tabs[_current];

  Future<void> _updateNavState() async {
    final bool back = await _tab.controller.canGoBack();
    final bool fwd = await _tab.controller.canGoForward();
    setState(() {
      _tab.canBack = back;
      _tab.canForward = fwd;
    });
  }

  void _createTab({required String initialUrl, bool makeCurrent = false}) {
    final WebViewController controller = WebViewController();
    final _TabData tab = _TabData(
      controller: controller,
      title: widget.title,
      url: initialUrl,
    );
    _tabs.add(tab);
    final int tabIndex = _tabs.length - 1;

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int p) =>
            setState(() => _tabs[tabIndex].progress = p / 100.0),
        onPageStarted: (String url) {
          setState(() {
            _tabs[tabIndex].url = url;
            if (_current == tabIndex) _address.text = url;
          });
        },
        onPageFinished: (String url) async {
          final String? t = await controller.getTitle();
          setState(() {
            _tabs[tabIndex].title = t ?? widget.title;
            _tabs[tabIndex].url = url;
            if (_current == tabIndex) _address.text = url;
          });
          _updateNavState();
        },
      ),
    );
    controller.loadRequest(Uri.parse(initialUrl));
    if (makeCurrent) {
      setState(() {
        _current = _tabs.length - 1;
        _address.text = initialUrl;
      });
    }
  }

  void _openNewTab([String? url]) {
    final String target = url ?? widget.url;
    _createTab(initialUrl: target, makeCurrent: true);
  }

  void _switchTo(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() {
      _current = index;
      _address.text = _tab.url;
    });
  }

  void _closeTab(int index) {
    if (_tabs.length == 1) return;
    setState(() {
      _tabs.removeAt(index);
      if (_current >= _tabs.length) _current = _tabs.length - 1;
      _address.text = _tab.url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: _tab.canBack
                          ? () async {
                              await _tab.controller.goBack();
                              _updateNavState();
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      onPressed: _tab.canForward
                          ? () async {
                              await _tab.controller.goForward();
                              _updateNavState();
                            }
                          : null,
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.lock, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _address,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search or enter URL',
                        ),
                        textInputAction: TextInputAction.go,
                        onSubmitted: (String value) {
                          final String v = value.trim();
                          if (v.isEmpty) return;
                          String toLoad;
                          // Try parse as URL
                          try {
                            final uri = Uri.parse(v);
                            // Jo scheme (http/https) nathi pan lagyu ke URL j che (ex: google.com)
                            if (!uri.hasScheme && v.contains('.')) {
                              toLoad = 'https://$v';
                            }
                            // Jo valid http/https URL hoy
                            else if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
                              toLoad = v;
                            }
                            // Nahi to Google search
                            else {
                              toLoad = 'https://www.google.com/search?q=${Uri.encodeComponent(v)}';
                            }
                          } catch (e) {
                            // Parse fail → Google search
                            toLoad = 'https://www.google.com/search?q=${Uri.encodeComponent(v)}';
                          }

                          _tab.controller.loadRequest(Uri.parse(toLoad));
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _tab.controller.reload(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _openNewTab(widget.url),
                    ),
                    InkWell(
                      onTap: _showTabsSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _tabs.length.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_tab.progress < 1.0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _tab.progress,
                    minHeight: 3,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: WebViewWidget(controller: _tab.controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTabsSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _tabs.length,
          itemBuilder: (BuildContext context, int i) {
            final _TabData t = _tabs[i];
            return ListTile(
              leading: Icon(i == _current ? Icons.tab : Icons.tab_outlined),
              title: Text(
                t.title.isEmpty ? t.url : t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                t.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                  _closeTab(i);
                },
              ),
              onTap: () {
                Navigator.pop(context);
                _switchTo(i);
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
        );
      },
    );
  }
}

class _TabData {
  _TabData({required this.controller, required this.title, required this.url});
  final WebViewController controller;
  String title;
  String url;
  double progress = 0;
  bool canBack = false;
  bool canForward = false;
}
