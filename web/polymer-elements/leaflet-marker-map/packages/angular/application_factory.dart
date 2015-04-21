/**
 * Bootstrapping for Angular applications via [dart:mirrors](https://api.dartlang
 * .org/apidocs/channels/stable/dartdoc-viewer/dart-mirrors) for development.
 *
 * Angular apps that use  [applicationFactory](#angular-app-factory@id_dynamicApplication) rely on
 * dynamic transformation at compile time to generate the getters, setters, annotations, and
 * factories needed for tree shaking during compilation with `dart2js`. See the [angular:app]
 * (#angular-app) library for a discussion of how this works.
 */
library angular.app.factory;

import 'package:angular/angular.dart';
import 'package:angular/core/registry.dart';
import 'package:angular/core/parser/parser.dart' show ClosureMap;
import 'package:angular/change_detection/change_detection.dart';
import 'package:angular/change_detection/dirty_checking_change_detector_dynamic.dart';
import 'package:angular/core/registry_dynamic.dart';
import 'package:angular/core/parser/dynamic_closure_map.dart';
import 'package:angular/core_dom/type_to_uri_mapper.dart';
import 'package:angular/core_dom/type_to_uri_mapper_dynamic.dart';
import 'dart:html';

/**
 * If you are writing code accessed from Angular expressions, you must include
 * your own @MirrorsUsed annotation or ensure that everything is tagged with
 * the Ng annotations.
 */
@MirrorsUsed(targets: const [
    'angular',
    'angular.core_internal',
    'angular.core.dom_internal',
    'angular.formatter',
    'angular.perf',
    'angular.directive',
    'angular.routing',
    'angular.core.annotation_src',
    'angular.core.parser.Parser',
    'angular.core.parser',
    'angular.core.parser.lexer',
    'angular.core_dom.type_to_uri_mapper_dynamic',
    'angular.core_dynamic.DynamicMetadataExtractor',
    'perf_api',
    List,
    NodeTreeSanitizer,
],
metaTargets: const [
    Injectable,
    Decorator,
    Component,
    Formatter
])
import 'dart:mirrors' show MirrorsUsed;

class _DynamicApplication extends Application {
  _DynamicApplication() {
    ngModule
        ..bind(TypeToUriMapper, toImplementation: DynamicTypeToUriMapper)
        ..bind(MetadataExtractor, toImplementation: DynamicMetadataExtractor)
        ..bind(FieldGetterFactory, toImplementation: DynamicFieldGetterFactory)
        ..bind(ClosureMap, toImplementation: DynamicClosureMap);
  }
}

/**
 * Creates an `applicationFactory` that bootstraps Angular as part of the `main()` function.
 *
 *     main() {
 *       applicationFactory()
 *         .addModule(new MyModule())
 *         .run();
 *     }
 *
 * During `pub build`, `applicationFactory()` is replaced by `staticApplication()` and
 * populated with the getters, setters, annotations, and factories generated by
 * Angular's transformers for dart2js compilation.
 */
Application applicationFactory() => new _DynamicApplication();