// This file is part of ChatBot.
//
// ChatBot is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChatBot is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ChatBot. If not, see <https://www.gnu.org/licenses/>.

import "package:http/http.dart";
import "package:langchain_core/documents.dart";
import "package:langchain_core/document_loaders.dart";
import "package:beautiful_soup_dart/beautiful_soup.dart";

class WebLoader extends BaseDocumentLoader {
  const WebLoader(
    this.urls, {
    this.client,
    this.requestHeaders,
    this.timeout = const Duration(seconds: 10),
  });

  final Client? client;
  final Duration timeout;
  final List<String> urls;
  final Map<String, String>? requestHeaders;

  @override
  Future<List<Document>> load() async {
    const badDocument = Document(pageContent: "");

    final docs = await Future.wait(urls.map(
        (it) => _scrape(it).timeout(timeout).catchError((_) => badDocument)));
    docs.removeWhere((it) => it.pageContent.isEmpty);

    return docs;
  }

  @override
  Stream<Document> lazyLoad() async* {
    for (final url in urls) {
      final doc = await _scrape(url);
      yield doc;
    }
  }

  Future<Document> _scrape(final String url) async {
    final html = await _fetchUrl(url);
    final soup = BeautifulSoup(html);
    final body = soup.body!;

    body.findAll("script").forEach((e) => e.extract());
    body.findAll("style").forEach((e) => e.extract());

    final content = body.getText(strip: true);
    return Document(
      pageContent: content,
      metadata: _buildMetadata(url, soup),
    );
  }

  Future<String> _fetchUrl(final String url) async {
    final clnt = client ?? Client();
    final res = await clnt.get(
      Uri.parse(url),
      headers: requestHeaders,
    );
    return res.body;
  }

  Map<String, dynamic> _buildMetadata(
    final String url,
    final BeautifulSoup soup,
  ) {
    final title = soup.title;
    final language = soup.find("html")?.getAttrValue("lang");
    final description = soup
        .find("meta", attrs: {"name": "description"})?.getAttrValue("content");

    return {
      "source": url,
      if (title != null) "title": title.text,
      if (language != null) "language": language,
      if (description != null) "description": description.trim(),
    };
  }
}
