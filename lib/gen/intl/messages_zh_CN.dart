// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_CN locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh_CN';

  static String m0(pages, text) =>
      "提示词模板中的 ${pages} 占位变量会被网页内容替换，${text} 占位变量会被用户消息替换。如不清楚，可留空以使用内置模板。";

  static String m1(text) => "提示词模板中的 ${text} 占位变量会被用户消息替换。如不清楚，可留空以使用内置模板。";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "all_chats": MessageLookupByLibrary.simpleMessage("所有对话"),
        "api": MessageLookupByLibrary.simpleMessage("接口"),
        "api_key": MessageLookupByLibrary.simpleMessage("接口密钥"),
        "api_type": MessageLookupByLibrary.simpleMessage("接口类型"),
        "api_url": MessageLookupByLibrary.simpleMessage("接口地址"),
        "apis": MessageLookupByLibrary.simpleMessage("接口"),
        "base_config": MessageLookupByLibrary.simpleMessage("基本配置"),
        "bot": MessageLookupByLibrary.simpleMessage("角色"),
        "bots": MessageLookupByLibrary.simpleMessage("角色"),
        "camera": MessageLookupByLibrary.simpleMessage("相机"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "cannot_open": MessageLookupByLibrary.simpleMessage("无法打开"),
        "chat_image_compress": MessageLookupByLibrary.simpleMessage("对话图片压缩"),
        "chat_model": MessageLookupByLibrary.simpleMessage("对话模型"),
        "chat_model_hint": MessageLookupByLibrary.simpleMessage("是否是对话模型？"),
        "chat_settings": MessageLookupByLibrary.simpleMessage("对话设置"),
        "chat_title": MessageLookupByLibrary.simpleMessage("对话标题"),
        "check_for_updates": MessageLookupByLibrary.simpleMessage("检查更新"),
        "choose_api": MessageLookupByLibrary.simpleMessage("选择接口"),
        "choose_bot": MessageLookupByLibrary.simpleMessage("选择角色"),
        "choose_model": MessageLookupByLibrary.simpleMessage("选择模型"),
        "chunk_n": MessageLookupByLibrary.simpleMessage("块数量"),
        "chunk_n_hint": MessageLookupByLibrary.simpleMessage("集成到上下文中的块数量"),
        "chunk_overlap": MessageLookupByLibrary.simpleMessage("块重叠"),
        "chunk_overlap_hint":
            MessageLookupByLibrary.simpleMessage("与上一块重叠部分的大小"),
        "chunk_size": MessageLookupByLibrary.simpleMessage("块大小"),
        "chunk_size_hint": MessageLookupByLibrary.simpleMessage("单块能包含的最大字符数"),
        "citations": MessageLookupByLibrary.simpleMessage("引用"),
        "clear": MessageLookupByLibrary.simpleMessage("清空"),
        "clear_chat": MessageLookupByLibrary.simpleMessage("清空对话"),
        "clear_data": MessageLookupByLibrary.simpleMessage("清理数据"),
        "clear_data_audio": MessageLookupByLibrary.simpleMessage("所有的 TTS 缓存"),
        "clear_data_chat": MessageLookupByLibrary.simpleMessage("所有的对话数据"),
        "clear_data_image": MessageLookupByLibrary.simpleMessage("所有的图片生成结果"),
        "cleared_successfully": MessageLookupByLibrary.simpleMessage("清理成功"),
        "clearing": MessageLookupByLibrary.simpleMessage("清理中..."),
        "clone_chat": MessageLookupByLibrary.simpleMessage("复制对话"),
        "cloned_successfully": MessageLookupByLibrary.simpleMessage("复制成功"),
        "complete_all_fields": MessageLookupByLibrary.simpleMessage("请填写所有字段"),
        "config": MessageLookupByLibrary.simpleMessage("配置"),
        "config_hint": MessageLookupByLibrary.simpleMessage(
            "为避免导出失败，建议将配置导出到 Documents 目录，或在 Download 下创建 ChatBot 子目录。"),
        "config_import_export": MessageLookupByLibrary.simpleMessage("配置导入导出"),
        "copied_successfully": MessageLookupByLibrary.simpleMessage("拷贝成功"),
        "copy": MessageLookupByLibrary.simpleMessage("拷贝"),
        "default_config": MessageLookupByLibrary.simpleMessage("默认配置"),
        "delete": MessageLookupByLibrary.simpleMessage("删除"),
        "delete_image": MessageLookupByLibrary.simpleMessage("删除图片"),
        "document": MessageLookupByLibrary.simpleMessage("文档"),
        "document_config": MessageLookupByLibrary.simpleMessage("文档配置"),
        "document_config_hint": MessageLookupByLibrary.simpleMessage(
            "文档会被划分为若干块，经过搜索比较后，最合适的几个块会被补充进上下文。"),
        "download": MessageLookupByLibrary.simpleMessage("下载"),
        "duplicate_api_name": MessageLookupByLibrary.simpleMessage("接口名重复"),
        "duplicate_bot_name": MessageLookupByLibrary.simpleMessage("角色名重复"),
        "edit": MessageLookupByLibrary.simpleMessage("编辑"),
        "embedding_vector": MessageLookupByLibrary.simpleMessage("嵌入向量"),
        "embedding_vector_info": MessageLookupByLibrary.simpleMessage(
            "批大小受限于接口服务商，建议查询后修改。向量维度为专业选项，非必要请勿填写。"),
        "empty": MessageLookupByLibrary.simpleMessage("空"),
        "empty_link": MessageLookupByLibrary.simpleMessage("空链接"),
        "enable": MessageLookupByLibrary.simpleMessage("启用"),
        "ensure_clear_chat": MessageLookupByLibrary.simpleMessage("确定要清空对话？"),
        "ensure_delete_image": MessageLookupByLibrary.simpleMessage("确定要删除图片？"),
        "enter_a_name": MessageLookupByLibrary.simpleMessage("请输入名称"),
        "enter_a_title": MessageLookupByLibrary.simpleMessage("请输入标题"),
        "enter_message": MessageLookupByLibrary.simpleMessage("输入你的消息"),
        "enter_prompts": MessageLookupByLibrary.simpleMessage("请输入提示词"),
        "error": MessageLookupByLibrary.simpleMessage("错误"),
        "export_chat_as_image": MessageLookupByLibrary.simpleMessage("导出图片"),
        "export_config": MessageLookupByLibrary.simpleMessage("导出配置"),
        "exported_successfully": MessageLookupByLibrary.simpleMessage("导出成功"),
        "exporting": MessageLookupByLibrary.simpleMessage("正在导出..."),
        "failed_to_export":
            MessageLookupByLibrary.simpleMessage("无法在该目录下写入文件。"),
        "gallery": MessageLookupByLibrary.simpleMessage("图库"),
        "generate": MessageLookupByLibrary.simpleMessage("生成"),
        "image_compress_failed": MessageLookupByLibrary.simpleMessage("图片压缩失败"),
        "image_enable_hint": MessageLookupByLibrary.simpleMessage("压缩失败则将使用原图"),
        "image_generation": MessageLookupByLibrary.simpleMessage("图像生成"),
        "image_hint": MessageLookupByLibrary.simpleMessage(
            "质量范围应在 1-100，质量越低压缩率越高。最小宽度与最小高度用于限制图片缩放，如不清楚，请留空。"),
        "image_quality": MessageLookupByLibrary.simpleMessage("图像质量"),
        "image_size": MessageLookupByLibrary.simpleMessage("图像尺寸"),
        "image_style": MessageLookupByLibrary.simpleMessage("图像风格"),
        "images": MessageLookupByLibrary.simpleMessage("图片"),
        "import_config": MessageLookupByLibrary.simpleMessage("导入配置"),
        "imported_successfully": MessageLookupByLibrary.simpleMessage("导入成功"),
        "importing": MessageLookupByLibrary.simpleMessage("正在导入..."),
        "invalid_max_tokens": MessageLookupByLibrary.simpleMessage("非法的最大输出"),
        "invalid_temperature": MessageLookupByLibrary.simpleMessage("非法的温度"),
        "link": MessageLookupByLibrary.simpleMessage("链接"),
        "max_tokens": MessageLookupByLibrary.simpleMessage("最大输出"),
        "min_height": MessageLookupByLibrary.simpleMessage("最小高度"),
        "min_width": MessageLookupByLibrary.simpleMessage("最小宽度"),
        "min_width_height": MessageLookupByLibrary.simpleMessage("最小宽高"),
        "model": MessageLookupByLibrary.simpleMessage("模型"),
        "model_avatar": MessageLookupByLibrary.simpleMessage("模型头像"),
        "model_list": MessageLookupByLibrary.simpleMessage("模型列表"),
        "model_name": MessageLookupByLibrary.simpleMessage("模型名称"),
        "name": MessageLookupByLibrary.simpleMessage("名称"),
        "new_api": MessageLookupByLibrary.simpleMessage("新接口"),
        "new_bot": MessageLookupByLibrary.simpleMessage("新角色"),
        "new_chat": MessageLookupByLibrary.simpleMessage("新对话"),
        "no_model": MessageLookupByLibrary.simpleMessage("无模型"),
        "not_implemented_yet": MessageLookupByLibrary.simpleMessage("还未实现"),
        "ok": MessageLookupByLibrary.simpleMessage("确定"),
        "open": MessageLookupByLibrary.simpleMessage("打开"),
        "optional_config": MessageLookupByLibrary.simpleMessage("可选配置"),
        "other": MessageLookupByLibrary.simpleMessage("其他"),
        "play": MessageLookupByLibrary.simpleMessage("播放"),
        "please_input": MessageLookupByLibrary.simpleMessage("请输入"),
        "quality": MessageLookupByLibrary.simpleMessage("质量"),
        "reanswer": MessageLookupByLibrary.simpleMessage("重答"),
        "reset": MessageLookupByLibrary.simpleMessage("重置"),
        "restart_app": MessageLookupByLibrary.simpleMessage("请重启应用以加载新配置。"),
        "save": MessageLookupByLibrary.simpleMessage("保存"),
        "saved_successfully": MessageLookupByLibrary.simpleMessage("保存成功"),
        "search_gemini_mode":
            MessageLookupByLibrary.simpleMessage("Google Search 模式"),
        "search_general_mode": MessageLookupByLibrary.simpleMessage("通用模式"),
        "search_n": MessageLookupByLibrary.simpleMessage("网页数量"),
        "search_n_hint": MessageLookupByLibrary.simpleMessage("检索的网页数量上限"),
        "search_prompt": MessageLookupByLibrary.simpleMessage("提示词"),
        "search_prompt_hint":
            MessageLookupByLibrary.simpleMessage("用于合成上下文的提示词模板"),
        "search_prompt_info": m0,
        "search_searxng": MessageLookupByLibrary.simpleMessage("SearXNG"),
        "search_searxng_base": MessageLookupByLibrary.simpleMessage("根地址"),
        "search_searxng_extra": MessageLookupByLibrary.simpleMessage("附加参数"),
        "search_searxng_extra_help": MessageLookupByLibrary.simpleMessage(
            "例如：engines=google&language=zh"),
        "search_searxng_hint":
            MessageLookupByLibrary.simpleMessage("SearXNG 实例"),
        "search_timeout": MessageLookupByLibrary.simpleMessage("超时时间"),
        "search_timeout_fetch": MessageLookupByLibrary.simpleMessage("抓取超时"),
        "search_timeout_fetch_help":
            MessageLookupByLibrary.simpleMessage("抓取网页内容的超时时间"),
        "search_timeout_hint": MessageLookupByLibrary.simpleMessage("检索的超时毫秒数"),
        "search_timeout_query": MessageLookupByLibrary.simpleMessage("检索超时"),
        "search_timeout_query_help":
            MessageLookupByLibrary.simpleMessage("请求 SearXNG 的超时时间"),
        "search_vector": MessageLookupByLibrary.simpleMessage("嵌入向量"),
        "search_vector_hint": MessageLookupByLibrary.simpleMessage("建议开启"),
        "select_models": MessageLookupByLibrary.simpleMessage("选择模型"),
        "settings": MessageLookupByLibrary.simpleMessage("设置"),
        "setup_api_model_first":
            MessageLookupByLibrary.simpleMessage("请先配置接口和模型"),
        "setup_searxng_first":
            MessageLookupByLibrary.simpleMessage("请先配置 SearXNG 实例"),
        "setup_tts_first": MessageLookupByLibrary.simpleMessage("请先配置文本转语音"),
        "setup_vector_first":
            MessageLookupByLibrary.simpleMessage("请先配置嵌入向量接口和模型"),
        "share": MessageLookupByLibrary.simpleMessage("分享"),
        "source": MessageLookupByLibrary.simpleMessage("源码"),
        "streaming_response": MessageLookupByLibrary.simpleMessage("流式响应"),
        "system_prompts": MessageLookupByLibrary.simpleMessage("系统提示词"),
        "task": MessageLookupByLibrary.simpleMessage("任务"),
        "temperature": MessageLookupByLibrary.simpleMessage("温度"),
        "text_to_speech": MessageLookupByLibrary.simpleMessage("文本转语音"),
        "title": MessageLookupByLibrary.simpleMessage("ChatBot"),
        "title_enable_hint":
            MessageLookupByLibrary.simpleMessage("禁用则将以用户消息为标题"),
        "title_generation": MessageLookupByLibrary.simpleMessage("标题生成"),
        "title_generation_hint": m1,
        "title_prompt": MessageLookupByLibrary.simpleMessage("提示词"),
        "title_prompt_hint":
            MessageLookupByLibrary.simpleMessage("用于生成标题的提示词模板"),
        "up_to_date": MessageLookupByLibrary.simpleMessage("已是最新版本"),
        "vector_batch_size": MessageLookupByLibrary.simpleMessage("批大小"),
        "vector_batch_size_hint":
            MessageLookupByLibrary.simpleMessage("单次请求能提交的最大块数量"),
        "vector_dimensions": MessageLookupByLibrary.simpleMessage("向量维度"),
        "vector_dimensions_hint":
            MessageLookupByLibrary.simpleMessage("嵌入向量模型输出向量的维度"),
        "voice": MessageLookupByLibrary.simpleMessage("音色"),
        "web_search": MessageLookupByLibrary.simpleMessage("联网搜索"),
        "workspace": MessageLookupByLibrary.simpleMessage("工作空间")
      };
}
