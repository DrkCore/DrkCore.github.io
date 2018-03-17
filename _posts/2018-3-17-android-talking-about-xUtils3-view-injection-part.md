---
layout: post
title:  "Android：xUtils3浅析（一）——视图注入"
date:   2018-3-17 21:45:17 +0800
categories: Android
---

# 2018-3-17 更新

这篇文章其实已经写了近两年了，现在看来写的还算通顺。在今天（2018-3-17）将之从 CSDN 搬运到 GitHub Page 页面的时候又稍微做了点润色，同时不禁感慨 Android 开发框架的进步之快。

从今天的眼光来看笔者认为 xUtils3 的视图模块确实有点跟不上时代的。xUtils 最初的思路就是做一个大而全的框架，涵盖数据库、网络请求、视图注入和图片加载的功能足够支撑起一个应用的开发，这个思路也被 xUtils3 所继承。但是随着业界的发展各种“专注于干好一件事”的新框架们开始崭露头角，将各自领做到极致并分食掉对应的市场。

就拿视图注入这块内容来说，笔者目前使用的解决方案是 [Butterknife](https://github.com/JakeWharton/butterknife)。其特点想必大家也有所了解，不再细说。针对其没有 `ContentView` 注解的问题笔者还特地开发了个新框架来弥补这一点，有兴趣的请移步笔者的开源地址 [GitHub: ContentViewAnnotation](https://github.com/DrkCore/ContentViewAnnotation)。

当然这些话并不是说 xUtils 框架有多不好，如果想要了解如何完整的写出一个新框架的话，将之细细研读还是会大有收获的。

# 前言

如果你能点进这篇博文，说明你和笔者一样也是使用 xUtils 的 Android 开发者。作为国内老牌的框架 xUtils 的功能禁得起考验。在版本升级到了 [xUtils3](https://github.com/wyouflf/xUtils3) 后笔者果断 fork 了一波。

在接下来的篇幅中笔者将为你简单介绍一下 xUtils3 的视图注入模块的实现方式。

该模块是 xUtils3 四大模块中最简单的一个，其所有的逻辑都在主线程中完成且基本只在界面启动时调用一次，因而将之作为理解 xUtils3 源码的第一步而言再合适不过了。

在旧版中视图模块除了查找视图外还能使用注解将资源（比如 String 或者 Drawable 等）绑定到成员变量上，但是 xUtils3 中该模块就只专心做视图注入和事件绑定了。这倒算是一件好事，因为说实话资源注入用的很少而且到要用资源时才加载会更轻快一些。

废话不多说了，让我们进入正题。

要讲视图注入模块首先要讲的肯定是注解，如果你对注解还不了解的话请点此[度娘传送门](http://www.baidu.com/s?ie=utf-8&f=8&rsv_bp=1&tn=baidu&wd=JAVA%20注解&oq=注解成员&rsv_pq=d95a73e00001d341&rsv_t=90da7NAMcMNlNA797KOIS2f7V2SaOKYaYz0a%2FZqrKOX0dia7lJlMZYBlAQI&rsv_enter=1&rsv_sug3=16&rsv_sug1=9&rsv_sug7=100&rsv_sug2=0&inputT=4846&rsv_sug4=5367)自行学习，在之后的章节中默认你们已经了解了注解的基本使用方法。

在 xUtils3 的 [org.xutils.view.annotation](https://github.com/wyouflf/xUtils3/tree/master/xutils/src/main/java/org/xutils/view/annotation) 包中可以看到我们平常使用的三个注解：ViewInject、ContentView、Event。

# 从 ViewInject 注解开始

[ViewInject](https://github.com/wyouflf/xUtils3/blob/master/xutils/src/main/java/org/xutils/view/annotation/ViewInject.java) 注解本身没什么内容：

```java
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface ViewInject {

    int value();

    /* parent view id */
    int parentId() default 0;
}
```

大体就是用两个属性标出视图的位置信息，```int value()``` 自然就是用来标志视图的 id 的而 ```int parentId()``` 是用来标志目标所在的父视图的id，这样就可以通过查找父视图来区分两个同id的视图（如果你愿意在一个 xml 里使用同一个 id 两次的话）。

注解本身只起到了标注的作用，真正的逻辑实现则写在了 [ViewInjectorImpl](https://github.com/wyouflf/xUtils3/blob/master/xutils/src/main/java/org/xutils/view/ViewInjectorImpl.java) 类的方法中：

```java
void injectObject(Object handler, Class handlerType, ViewFinder finder)
```

形参中的 handler 是需要绑定视图的实例，其类可以是 Activity、Fragment 甚至是自定义 ViewHolder，只要有成员变量被 ViewInject 标注即可；

handlerType 自然是handler.getClass()，不解释；

需要注意的是 ViewFinder。我们知道在 Androd 中拥有 `findViewById(int)` 这个方法的只有 View 和 Activity，而 ViewFinder 是二者的装饰者，挺简单的，具体实现瞟一眼[源码](https://github.com/wyouflf/xUtils3/blob/master/xutils/src/main/java/org/xutils/view/ViewFinder.java)你就懂了。

接着让我来看看 injectObject 中使用 ViewInject 的关键代码：

```java
// inject view
// 这里我们可以看到使用反射获取定义的成员变量
Field[] fields = handlerType.getDeclaredFields();
if (fields != null && fields.length > 0) {
    for (Field field : fields) {
        //跳过无法注入或者不需要注入的字段
        Class<?> fieldType = field.getType();
        if (
        /* 不注入静态字段 */     Modifier.isStatic(field.getModifiers()) ||
        /* 不注入final字段 */    Modifier.isFinal(field.getModifiers()) ||
        /* 不注入基本类型字段 */  fieldType.isPrimitive() ||
        /* 不注入数组类型字段 */  fieldType.isArray()) {
            continue;
        }

        // 检查该成员变量的域是否被 ViewInject 注解所标注
        ViewInject viewInject = field.getAnnotation(ViewInject.class);
        if (viewInject != null) {
            try {
                // 从 viewInject 中找出目标 View 的 id 并且使用 ViewFinder 来查找对应的视图
                // 上文说的 parentId() 在这个地方用上了
                View view = finder.findViewById(viewInject.value(), viewInject.parentId());
                if (view != null) {
                    // 剩下的就是打开权限然后用反射赋值，轻车熟路
                    field.setAccessible(true);
                    field.set(handler, view);
                } else {
                    // 如果用 ViewInject 注解了但是找不到视图的话几乎可以肯定是编码错误，这里作者直接抛出了运行时异常
                    throw new RuntimeException("Invalid @ViewInject for "
                            + handlerType.getSimpleName() + "." + field.getName());
                }
            } catch (Throwable ex) {
                // 上面如果找不到 View 抛出 RuntimeException 的话也会到这里来然后被这个能消化 Trowable 的 catch 给吃掉
                // 结果就是一旦找不到一个 View 视图注入的整个流程都将被终止掉

                // 所以如果你用 xUtils3 多的话就会遇到明明是实例化 XML 炸了导致注入视图失败
                // 你得到的却是因为使用了未被注入的成员导致 NullPointer 的坑

                // 这里作者倒是还写了一个 LogUtil 用来避免输出的日志泄露
                // 写代码久的人多少都有一个自己的LogUtil
                LogUtil.e(ex.getMessage(), ex);
            }
        }
    }
} // end inject view
```

以上就是 ViewInject 注解的核心逻辑，整体思路如下：

1. 通过注解标记成员变量
2. 反射获取注解的信息
3. findView 后反射赋值给成员变量

# ContentView 注解

[ContentView](https://github.com/wyouflf/xUtils3/blob/master/xutils/src/main/java/org/xutils/view/annotation/ContentView.java) 注解只有一个 ```int value()``` 属性，显然是用来标志 layout 的资源 id 的，代码太少就不贴上来了。

主要逻辑同样是在 ```ViewInjectorImpl``` 类中，该类中有很多 inject() 的重载方法，其中针对 Activity 的方法如下：

```java
// 该方法是用来注入 Activity 实例的
@Override
public void inject(Activity activity) {
    // 获取 Activity 的 ContentView 的注解
    Class<?> handlerType = activity.getClass();
    try {
        // findContentView 方法是定义在 ViewInjectorImpl 下文中的方法
        // 如你所见是几行用于获取注解的标准姿势，因篇幅有限故不展开
        ContentView contentView = findContentView(handlerType);
        if (contentView != null) {
            int viewId = contentView.value();
            if (viewId > 0) {
                // 用反射调用 Activity.setContentView(int) 方法
                // 尽管笔者一直觉得这里并没有用反射的必要
                Method setContentViewMethod = handlerType.getMethod("setContentView", int.class);
                setContentViewMethod.invoke(activity, viewId);
            }
        }
    } catch (Throwable ex) {
        LogUtil.e(ex.getMessage(), ex);
    }

    // setContentView 之后再直接注入其他的东西
    injectObject(activity, handlerType, new ViewFinder(activity));
}
```

除了 Activity 之外，ContentView 注解还能用在 Fragment 上的。

旧版本的 xUtils 的视图注入模块让人比较诟病的一点就是没办法对 Fragment 进行视图注入，你只能在 onCreateView() 方法中自己用 inflater 实例化一个 View 返回，然后在 onViewCreated 里面对已经实例化的 view 进行注入。不少开发者由于无法忍受冗长的代码（虽然只有几行但就是不爽）从而走上了 fork 的不归路（包括笔者）。

好在在 xUtils3 里面作者明显考虑到了这一点，以下是针对 Fragment 的核心代码：

```java
// 该方法是用来注入 Fragment 实例的
// 你会注意到这里的形参中除了开始的 Object fragment 之外还有着 Layoutinflater 和 ViewGroup
// 明显对应着 Fragment.onCreateView() 回调方法
@Override
public View inject(Object fragment, LayoutInflater inflater, ViewGroup container) {
    // inject ContentView
    View view = null;
    Class<?> handlerType = fragment.getClass();
    try {
        ContentView contentView = findContentView(handlerType);
        if (contentView != null) {
            int viewId = contentView.value();
            if (viewId > 0) {
                // 在这里 xUtils3 把我们写了无数遍的那行代码写掉了，简直就是拯救强迫症的福音
                view = inflater.inflate(viewId, container, false);
            }
        }
    } catch (Throwable ex) {
        LogUtil.e(ex.getMessage(), ex);
    }

    // inject res & event
    // 和上面一样，准备好了内容布局之后直接上 injectObject() 方法注入其他的东西
    injectObject(fragment, handlerType, new ViewFinder(view));

    // 返回 View 的实例
    // 这样 Fragment.onCreateView() 方法只需要一行代码就行了
    // 可以通过写基类将这一行代码封装掉
    return view;
}
```

# Event 注解

[Event](https://github.com/wyouflf/xUtils3/blob/master/xutils/src/main/java/org/xutils/view/annotation/Event.java) 注解是视图模块的核心。想要读懂这部分的代码的话你可能需要先掌握以下动态代理的机制，如果你对此不甚了解的话可以先点击这个[度娘传送门](http://www.baidu.com/s?wd=JAVA+动态代理&ie=UTF-8)自行学习。

Event 注解的实现主要逻辑在 [org.xutils.view.EventListenerManager](https://github.com/wyouflf/xUtils3/blob/master/xutils/src/main/java/org/xutils/view/EventListenerManager.java) 中。

其中有一个名为 `DynamicHanlder` 的内部类，用于处理事件注入的代理逻辑，如下：

```java
// 事件接口的反射代理
public static class DynamicHandler implements InvocationHandler {

    // 存放代理对象，比如 Fragment 或 view holder
    // 这里你可以看到原作者使用了弱引用避免内存泄露
    private WeakReference<Object> handlerRef;
    // 存放代理方法
    // 比如 "onClick" 字符对应着被 Event 注解的方法 method
    private final HashMap<String, Method> methodMap = new HashMap<String, Method>(1);

    // 这里有一个标志位用于存储上一次点击的时间戳
    // 以此来避免用户点击的频率过高
    private static long lastClickTime = 0;

    public DynamicHandler(Object handler) {
        this.handlerRef = new WeakReference<Object>(handler);
    }

    public void addMethod(String name, Method method) {
        methodMap.put(name, method);
    }

    public Object getHandler() {
        return handlerRef.get();
    }

    // 对动态代理调用的任何方法都会通过这个invoke 方法来执行
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        Object handler = handlerRef.get();
        if (handler != null) {//当 hanlder 还未被回收
            String eventMethod = method.getName();
            if ("toString".equals(eventMethod)) {
                // toString 特殊处理
                // 如果没有这部处理当调用了 proxy.toString() 的话会产生无限递归导致栈溢出
                return DynamicHandler.class.getSimpleName();
            }

            // 按照名字从映射关系中取出真正被映射着的那个方法
            // 比如按照 "onClick" 取出你的 doSomething() 方法
            method = methodMap.get(eventMethod);
            if (method == null && methodMap.size() == 1) {
                // 如果映射关系中只有一个那必定是 onClick 的映射
                // 这里解释了为什么 Event 不指定 type 时仍能触发 onClick 方法
                for (Map.Entry<String, Method> entry : methodMap.entrySet()) {
                    if (TextUtils.isEmpty(entry.getKey())) {
                        method = entry.getValue();
                    }
                    break;
                }
            }

            if (method != null) {
                // 避免用户点击的频率太快
                if (AVOID_QUICK_EVENT_SET.contains(eventMethod)) {
                    long timeSpan = System.currentTimeMillis() - lastClickTime;
                    if (timeSpan < QUICK_EVENT_TIME_SPAN) {
                        LogUtil.d("onClick cancelled: " + timeSpan);
                        return null;
                    }
                    lastClickTime = System.currentTimeMillis();
                }

                try {// 反射触发被映射的方法
                    return method.invoke(handler, args);
                } catch (Throwable ex) {
                    throw new RuntimeException("invoke method error:" +
                            handler.getClass().getName() + "#" + method.getName(), ex);
                }
            } else {
                LogUtil.w("method not impl: " + eventMethod + "(" + handler.getClass().getSimpleName() + ")");
            }
        }
        return null;
    }
}
```

整体的思路是：

1. 注解标记方法
2. 使用动态代理构建 listener 的代理实例
3. 将方法回调分配到被注解标记的方法中

# 总结

视图注解模块主要用到的知识点是：运行时注解、反射、动态代理，掌握这些知识后自己写一个类似的功能就不再是一个难事。当然，知道轮子怎么造就行了，没必要自己再造一个。

笔者会在自己的一些对性能没有什么要求小项目上使用这个模块，但对于部分其他的 Android 程序员而言则会认为过多地使用反射会拖慢应用的速度，如何选择还请根据项目实际来决定。

以上即是笔者的 xUtils3 的视图注解模块的粗浅理解，如有纰漏，还望赐教。
