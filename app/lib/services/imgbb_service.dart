import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../imgbb_config.dart';

class ImgBBService {
  Future<Map<String, String>> enviarImagem(XFile imagem) async {
    final tamanho = await imagem.length();

    if (tamanho == 0) {
      throw Exception('A imagem está vazia.');
    }

    // Limite local para este protótipo: 5 MB.
    // A API documenta um limite de até 32 MB.
    const tamanhoMaximo = 5 * 1024 * 1024;
    if (tamanho > tamanhoMaximo) {
      throw Exception('A imagem deve ter no máximo 5 MB.');
    }

    if (ImgBBConfig.apiKey == 'COLOQUE_SUA_CHAVE_IMGBB_AQUI' ||
        ImgBBConfig.apiKey.trim().isEmpty) {
      throw Exception(
        'Configure sua chave da API do ImgBB em '
        'lib/imgbb_config.dart.',
      );
    }

    final bytes = await imagem.readAsBytes();
    final uri = Uri.parse(ImgBBConfig.uploadUrl).replace(
      queryParameters: {'key': ImgBBConfig.apiKey},
    );

    final requisicao = http.MultipartRequest('POST', uri);
    requisicao.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imagem.name,
      ),
    );

    final resposta = await http.Response.fromStream(
      await requisicao.send().timeout(const Duration(seconds: 60)),
    );

    final Map<String, dynamic> dados;
    try {
      dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'O ImgBB retornou uma resposta inválida '
        '(HTTP ${resposta.statusCode}).',
      );
    }

    final status = dados['status'];
    final sucesso = dados['success'] == true;
    final data = dados['data'];

    if (resposta.statusCode < 200 ||
        resposta.statusCode >= 300 ||
        !sucesso ||
        (status is num && status != 200) ||
        data is! Map) {
      final error = dados['error'];
      final message = error is Map
          ? error['message']
          : dados['status_txt'] ?? 'erro desconhecido';
      throw Exception('Falha no upload para ImgBB: $message.');
    }

    final url = data['url'];
    final urlViewer = data['url_viewer'];
    final deleteUrl = data['delete_url'];

    if (url is! String || url.isEmpty) {
      throw Exception('A API não retornou a URL direta da imagem.');
    }

    if (urlViewer is! String || urlViewer.isEmpty) {
      throw Exception('A API não retornou a página da imagem.');
    }

    return {
      'url': url,
      'urlViewer': urlViewer,
      if (deleteUrl is String && deleteUrl.isNotEmpty)
        'deleteUrl': deleteUrl,
    };
  }
}
