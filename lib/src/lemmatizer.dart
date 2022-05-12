import 'package:flutter/services.dart';
import 'package:lemmatizer/enum.dart';

class Lemmatizer {
  // ignore: constant_identifier_names
  static const WN_FILES = {
    POS.NOUN: ['index_noun.txt', 'noun_exc.txt'],
    POS.VERB: ['index_verb.txt', 'verb_exc.txt'],
    POS.ADJ: ['index_adj.txt', 'adj_exc.txt'],
    POS.ADV: ['index_adv.txt', 'adv_exc.txt']
  };

  // ignore: constant_identifier_names
  static const MORPHOLOGICAL_SUBSTITUTIONS = {
    /// RULES
    POS.NOUN: [
      ['s', ''],
      ['ses', 's'],
      ['ves', 'f'],
      ['xes', 'x'],
      ['zes', 'z'],
      ['ches', 'ch'],
      ['shes', 'sh'],
      ['men', 'man'],
      ['ies', 'y']
    ],
    POS.VERB: [
      ['s', ''],
      ['ies', 'y'],
      ['ied', 'y'],
      ['es', 'e'],
      ['es', ''],
      ['ed', 'e'],
      ['ed', ''],
      ['ing', 'e'],
      ['ing', '']
    ],
    POS.ADJ: [
      ['er', ''],
      ['est', ''],
      ['er', 'e'],
      ['est', 'e']
    ],
    POS.ADV: [],
    POS.ABBR: [],
    POS.UNKNOWN: []
  };

  var wordlists = {};
  var exceptions = {};

  Lemmatizer() {
    wordlists = {};
    exceptions = {};

    for (var item in MORPHOLOGICAL_SUBSTITUTIONS.keys) {
      wordlists[item] = {};
      exceptions[item] = {};
    }

    for (var entry in WN_FILES.entries) {
      loadWordnetFiles(entry.key, entry.value[0], entry.value[1]);
    }
  }

  String lemma(form, {String? pos}) {
    var words = ["verb", "noun", "adj", "adv", "abbr"];
    form = form.toString().toLowerCase();
    if (!words.contains(pos)) {
      for (var item in words) {
        if (item == "verb") {
          String _samp = form;
          if (_samp.contains("ing")) {
            _samp = _samp.replaceFirst("ing", '');
            if (_samp.endsWith(
                _samp.substring(_samp.length - 2, _samp.length - 1))) {
              form = _samp.substring(0, _samp.length - 1);
            }
          }
        } else if (item == "adj") {
          String _samp = form;
          if (_samp.endsWith("est") || _samp.endsWith("er")) {
            if (_samp != "test") {
              if (_samp.endsWith("est")) {
                _samp = _samp.replaceFirst("est", "");
              } else if (_samp.endsWith("er")) {
                _samp = _samp.replaceFirst("er", "");
              }
              if (_samp.endsWith(
                  _samp.substring(_samp.length - 2, _samp.length - 1))) {
                form = _samp.substring(0, _samp.length - 1);
              } else if (_samp.substring(_samp.length - 1) == "i") {
                _samp = _samp.substring(0, _samp.length - 1);
                _samp = _samp + "y";
                form = _samp;
              }
            }
          }
        } else if (item == "noun") {
          String _samp = form;
          if (_samp.endsWith('ful')) {
            _samp = _samp.replaceAll("ful", '');
            if (_samp.endsWith("i")) {
              _samp = _samp.substring(0, _samp.length - 1);
              _samp = _samp + "y";
            }
            form = _samp;
          } else if (_samp.endsWith('full')) {
            _samp = _samp.replaceAll("full", '');
            if (_samp.endsWith("i")) {
              _samp = _samp.substring(0, _samp.length - 1);
              _samp = _samp + "y";
            }
            form = _samp;
          }
        }
        var result = lemma(form, pos: item);
        if (result != form) {
          return result;
        }
      }
      return form;
    }

    POS poss = strToPos(pos);
    var ea = eachLemma(form, poss);
    if (ea != null) {
      return ea;
    }
    return form;
  }

  Future<void> loadWordnetFiles(POS pos, list, exc) async {
    var fileList = await rootBundle.loadString("assets/" + list);
    var listLines = fileList.split("\n");

    for (var line in listLines) {
      var w = line.split(" ")[0];
      wordlists[pos][w] = w;
    }

    var fileExc = await rootBundle.loadString("assets/" + exc);
    var listExc = fileExc.split("\n");

    if (fileExc.trim().isNotEmpty) {
      for (var line in listExc) {
        if (line.trim().isNotEmpty) {
          var w = line.split(" ")[0];
          exceptions[pos][w[0]] = exceptions[pos][w[0]] ?? [];
          exceptions[pos][w[0]] = w[1];
        }
      }
    }
  }

  eachLemma(String form, POS pos) {
    var lemma = exceptions[pos][form];
    if (lemma != null) {
      return lemma;
    }

    return eachSubstitutions(form, pos);
  }

  eachSubstitutions(String form, POS pos) {
    var lemma = wordlists[pos][form];
    if (lemma != null) {
      return lemma;
    }

    var lst = MORPHOLOGICAL_SUBSTITUTIONS[pos]!;
    for (var item in lst) {
      var _old = item[0];
      var _new = item[1];
      if (form.endsWith(_old)) {
        var res = eachSubstitutions(
            form.substring(0, form.length - _old.length as int?) + _new, pos);
        if (res != null) {
          return res;
        }
      }
    }
  }

  POS strToPos(String? str) {
    switch (str) {
      case "n":
      case "noun":
        return POS.NOUN;
      case "v":
      case "verb":
        return POS.VERB;
      case "a":
      case "j":
      case "adjective":
      case "adj":
        return POS.ADJ;
      case "r":
      case "adverb":
      case "adv":
        return POS.ABBR;
      default:
        return POS.UNKNOWN;
    }
  }
}
