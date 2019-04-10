---
layout: post
title:  "Android：ButterKnife 的简要解读"
date:   2019-04-09 23:43:00 +0800
categories: Android
---

早几年大家可能接触过基于运行时注解的视图注入框架（比如 [xUtils3][1]），现在看来这种以牺牲运行时性能为代价换取源代码简洁度的方式有点太不划算，以至于当基于编译时注解的视图注入框架 [ButterKnife][2] 出现后很快就被淘汰了。

时至今日，通过 ButterKnife 来简化 `findViewById` 这样的重复代码对于 Android 开发者来说算已经习以为常。本着“格物致知”的精神我们有必要了解一下其中的奥秘，以便后续开发我们自己的框架。

编译时注解开发的基本流程是固定的：

1. 编写注解类
2. 收集注解信息
3. 生成源代码
4. 直接使用生成的代码逻辑，或者通过反射获取

以下介绍时默认大家对注解都有一定的了解，如果不甚熟练的可以另行找时间学习。

# 工程结构和注解类

编译时注解开发需要分模块处理，在 ButterKnife 中对应逻辑如下：

模块|存放|备注
-|-|-
[butterknife-annotations](https://github.com/JakeWharton/butterknife/tree/master/butterknife-annotations)|注解类|该模块可以是纯 Java 模块
[butterknife-compiler](https://github.com/JakeWharton/butterknife/tree/master/butterknife-compiler)|注解处理器|用于解析注解和生成源代码
[butterknife](https://github.com/JakeWharton/butterknife/tree/master/butterknife)|SDK 入口|反射调用生成的源代码

ButterKnife 的所有注解都可以在 `butterknife-annotations` 模块下找到，为了简化篇幅我们这里只介绍 `@BindView` 和 `@OnClick` 两个注解，其他的注解实现的大体思路是一样的，有兴趣的同学可以自行了解。

BindView 的源码：

```java
@Retention(RUNTIME) @Target(FIELD)
public @interface BindView {
  /** View ID to which the field will be bound. */
  @IdRes int value();
}
```

OnClick 的源码：

```java
@Target(METHOD)
@Retention(RUNTIME)
@ListenerClass(
    targetType = "android.view.View",
    setter = "setOnClickListener",
    type = "butterknife.internal.DebouncingOnClickListener",
    method = @ListenerMethod(
        name = "doClick",
        parameters = "android.view.View"
    )
)
public @interface OnClick {
  /** View IDs to which the method will be bound. */
  @IdRes int[] value() default { View.NO_ID };
}
```

可以看到这两个注解本身只提供基础的注入相关信息，要处理这些信息就需要使用注解处理器。

# 注解处理器

`butterknife-compiler` 是 ButterKnife 的`注解处理器模块，也该框架中最核心的部分。

注解处理器模块需要使用注解类并且需要依赖相应的 APT (Annotation Processor Tool)，在 `butterknife-compiler` 中这些依赖表示为：

```gradle
// 注解类
implementation project(':butterknife-annotations')
// Google 提供的注解处理工具，用于生成相应的 META-INF 信息
implementation 'com.google.auto.service:auto-service:1.0-rc4'
implementation 'com.google.auto:auto-common:0.10'
```

注解处理器需要继承 `AbstractProcessor` 并拓展相关的方法，以下是注解处理器的部分源码：

`process()` 方法是收集注解信息、解析并生成源代码的核心逻辑，可以看到这里将逻辑分拆到其他方法和类中：

```java
@Override public boolean process(Set<? extends TypeElement> elements, RoundEnvironment env) {
  //收集注解信息
  Map<TypeElement, BindingSet> bindingMap = findAndParseTargets(env);

  //生成注解类源代码
  for (Map.Entry<TypeElement, BindingSet> entry : bindingMap.entrySet()) {
    TypeElement typeElement = entry.getKey();
    BindingSet binding = entry.getValue();

    JavaFile javaFile = binding.brewJava(sdk, debuggable);
    try {
      javaFile.writeTo(filer);
    } catch (IOException e) {
      error(typeElement, "Unable to write binding for type %s: %s", typeElement, e.getMessage());
    }
  }

  return false;
}
```

`findAndParseTargets()` 收集

```java
  private Map<TypeElement, BindingSet> findAndParseTargets(RoundEnvironment env) {
    Map<TypeElement, BindingSet.Builder> builderMap = new LinkedHashMap<>();
    Set<TypeElement> erasedTargetNames = new LinkedHashSet<>();

    //收集 BindView 注解的信息，并将之填入 builderMap 中
    for (Element element : env.getElementsAnnotatedWith(BindView.class)) {
      try {
        parseBindView(element, builderMap, erasedTargetNames);
      } catch (Exception e) {
        logParsingError(element, BindView.class, e);
      }
    }

    //收集所有监听器的注解i信息，其中包括了 OnClick 注解
    for (Class<? extends Annotation> listener : LISTENERS) {
      findAndParseListener(env, listener, builderMap, erasedTargetNames);
    }

    //处理父类逻辑
    Deque<Map.Entry<TypeElement, BindingSet.Builder>> entries =
        new ArrayDeque<>(builderMap.entrySet());
    Map<TypeElement, BindingSet> bindingMap = new LinkedHashMap<>();
    while (!entries.isEmpty()) {
      Map.Entry<TypeElement, BindingSet.Builder> entry = entries.removeFirst();

      TypeElement type = entry.getKey();
      BindingSet.Builder builder = entry.getValue();

      TypeElement parentType = findParentType(type, erasedTargetNames);
      if (parentType == null) {
        bindingMap.put(type, builder.build());
      } else {
        BindingSet parentBinding = bindingMap.get(parentType);
        if (parentBinding != null) {
          builder.setParent(parentBinding);
          bindingMap.put(type, builder.build());
        } else {
          // 存在父类但是还未处理，
          entries.addLast(entry);
        }
      }
    }

    return bindingMap;
  }
```





[1]:https://github.com/wyouflf/xUtils3
[2]:https://github.com/JakeWharton/butterknife.git