---
layout: post
title:  "Android：策略模式在 Adapter 中的应用"
date:   2018-09-16 16:26:50 +0800
categories: Android
---


App 的首页向来是个寸土寸金的地方，如何在首页吸引用户是 PM 的工作，而对于我们开发者而言要做的就是适配。想必大家一定遇到过类似如下的设计稿：

![](./imgs/complicate_layout.jpg)

在设计稿上我们可以看到一些重点：

- 页面可以上下滚动
- 元素比较繁多
- 不同页之间有分割线或者间隙

基于上面的几点我们的思路无非分为两种，第一种就是：

**使用ScrollView包裹LinearLayout并动态add多个布局**

这种方法的是可以解决问题的，各个板块可以写成子布局，之间的风格线和间隙可以通过添加黑色的高度为 1px 的 View 和设置 MarginTop 来解决，重复的元素可以使用动态修改高度的 ListView 来适配。这种方法行之有效，但缺点是无法复用 View 比较浪费内存，且不好维护

第二条思路，也就是本篇博文将要论述的思路：

**将包括顶部的轮播图、中间的活动版面甚至是分割线和间隙在内的东西都当成 Item 布局，并使用单个ListView适配**

较之前者，该方法不但解决了复用 View 的问题而且视图的层次更少。

使用 RecyclerView 也是可以的不过思路其实和 ListView 一样，这里不再赘述，其对应的实现同样也在给出的源码中，请自行查阅。

之后的章节笔者会详细地阐述实现和代码，其中部分逻辑为了简化篇幅被省略掉了，如果你想直接看完整的源代码的话请直接跳转到文末。

## 策略模式

按照传统写多种布局的 Adapter 的时候我们都是需要在方法体内写上大量的 if-else 语句，用于区分当前的状态并根据对应的状态做相应的处理。如果条件的数量只有几个的话还可以接受，但是随着业务的拓展这样的代码将会变的又臭又长，几乎难以维护。

对这种**拥有多种状况，且状况与状况之间没有联系**的问题的常用解决方案就是策略模式

使用策略模式解决问题的第一步就是将每块用到的逻辑抽象成接口：

```java
/**
 * 用于创建ViewType指定的布局以及绑定对应的数据的接口，设计上而言，一种ViewType应当对应着一种Operator。
 *
 * @param <Item>
 */
public abstract class AbsItemType<Item> {

	// 判断能否处理对应类型的数据
    public abstract boolean canHandle(Object obj);

	// 创建数据对应的布局
    @NonNull
    public abstract SimpleViewHolder createViewHolder(Context context, LayoutInflater inflater, ViewGroup parent);

	// 将数据渲染到布局上
    public abstract void bindViewData(SimpleViewHolder holder, int position, Item data);
}
```

写好接口后我们就可以将 Adapter 简化成下方的样子：

```java
/**
 * 将对item的ViewHolder的创建和绑定数据解耦的适配器。
 * 你可以通过创建{@link AbsItemType#}的子类来灵活地创建item样式和行为。
 *
 * @author DrkCore
 * @since 2015年10月13日17:59:29
 */
public class FlexibleAdapter extends CoreAdapter {

	// 全部支持的策略
    private final List<AbsItemType> itemTypes = new ArrayList<>();

	// 通过 {@link AbsItemType#canHandle} 方法查找能够支持该数据的策略
    @Override
    public final int getItemViewType(int position) {
        Object obj = getItem(position);
        for (int i = 0, count = itemTypes.size(); i < count; i++) {
            if (itemTypes.get(i).canHandle(obj)) {
                return i;// 可处理
            }
        }
        // 填入了不可处理的类型
        throw new IllegalStateException("指定数据：" + obj + " 不存在可用的 type");
    }

    public FlexibleAdapter(AbsItemType<?>... itemTypes) {
        setTypes(itemTypes);
    }

    public final FlexibleAdapter setTypes(AbsItemType<?>... itemTypes) {
        if (!this.itemTypes.isEmpty()) {
            throw new IllegalStateException("Types 已经存在，无法重新初始化");
        } else if (itemTypes == null || itemTypes.length == 0) {
            throw new IllegalArgumentException("Types 不能为空");
        }

        for (int i = 0, len = itemTypes.length; i < len; i++) {
            itemTypes[i].onAttach(this);
            this.itemTypes.add(itemTypes[i]);
        }
        return this;
    }

    @NonNull
    @SuppressWarnings("unchecked")
    @Override
    protected final SimpleViewHolder createViewHolder(Context context, LayoutInflater inflater, ViewGroup parent, int viewType) {
		// 使用对应的策略来处理创建视图的逻辑
        return itemTypes.get(viewType).createViewHolder(context, inflater, parent);
    }

    @SuppressWarnings("unchecked")
    @Override
    protected final void bindViewData(SimpleViewHolder holder, int position, Object data, int viewType) {
		// 使用对应策略来处理渲染数据的逻辑
        AbsItemType operator = itemTypes.get(viewType);
        operator.bindViewData(holder, position, data);
    }

}
```

上方 `FlexibleAdapter` 类的父类 `CoreAdapter` 继承自 `BaseAdapter`，在实现的时候参考了 `Recycler.Adapter` 的设计将原本的 `getView()` 方法分拆成了 `createViewHolder()` 和 `bindViewData()` 两个方法，同时引入了自定义 `SimpleViewHolder` 类，借此可以省下很公式化的 ViewHolder 代码。

`BaseAdapter` 原本的职责是创建并渲染视图，`CoreAdapter` 将创建和渲染二者分拆开来，而进一步封装了的 `FlexibleAdapter` 的职责被简化成了调度策略，最终的创建和渲染实际上是交由策略类 `AbsItemType` 来执行的。

每个类的职责越单一就越容易维护。往后如果有新增的Item布局只需要新增一个独立的策略实现类即可，十分灵活。

## 实现一个策略

这里我们写一个策略以加深对这种思路的理解。布局文件很简单：

```java
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout
	xmlns:android="http://schemas.android.com/apk/res/android"
	android:layout_width="match_parent"
	android:layout_height="48dp"
	android:background="@color/core_white">

	<View
		android:layout_width="24dp"
		android:layout_height="16dp"
		android:layout_gravity="center_vertical"
		android:background="@color/core_holo_green_light"/>

	<TextView
		android:id="@+id/textView_listView_tip"
		android:layout_width="match_parent"
		android:layout_height="match_parent"
		android:gravity="center"
		android:orientation="vertical"/>
</FrameLayout>
```

有点经验的开发者应该立马就能想象到它实例化后的样子，主体只是一个用来显示文字的 TextView 而已。接下来是它对应的策略：

```java
public class TipOperator extends AbsItemOperator<Tip, TipViewHolder> {
	
	//写一个AbsViewHolder的基类，ViewHolder本身其实还可以深挖不少东西，这里篇幅有限就不再赘述
	public static class TipViewHolder extends AbsViewHolder<Tip> {

		public TipViewHolder(View v) {
			super(v);
		}
	}

	/*继承*/

	@Override
	public TipViewHolder createViewHolder(LayoutInflater inflater, ViewGroup parent) {
		//实例化布局
		View view = inflater.inflate(R.layout.activity_listview_tip, parent, false);
		//绑定事件
		view.setOnClickListener(this);
		return new TipViewHolder(textView);
	}

	@Override
	public void bindViewData(TipViewHolder holder, Tip data) {
		//绑定数据
		TextView textView = (TextView) holder.getView().findViewById(R.id.textView_listView_tip);
		textView.setText(data.tip);
	}

}
```

实际使用时如下：

```java
@Override
protected void onCreate(@Nullable Bundle savedInstanceState) {
	super.onCreate(savedInstanceState);
	ListView listView = new ListView(this);
	listView.setDivider(null);
	listView.setDividerHeight(0);
	setContentView(listView);
	setTitle(getClass().getSimpleName());

	//实例话FlexibleAdapter并填入所有的布局策略
	FlexibleAdapter adapter = new FlexibleAdapter(new RotateOperator(), new TipOperator(), new PanelOperator(), new MsgOperator(), new DividerOperator(), new SpanOperator());
	listView.setAdapter(adapter);

	//逐一添加每个数据项
	List<Object> list = new ArrayList<>();
	Rotate rotate = new Rotate(R.layout.activity_listview_rotate_1, R.layout.activity_listview_rotate_2, R.layout.activity_listview_rotate_3);
	list.add(rotate);
	list.add(new Divider());

	list.add(new Span());

	int times = 5;
	while (times-- > 0) {
		list.add(new Divider());
		Tip tip = new Tip("这是一个Tip");
		list.add(tip);
		list.add(new Divider());
		Panel panel = new Panel("这个是内容，我就随便输入一些什么东西");
		list.add(panel);
		list.add(new Divider());
		list.add(new Span());
	}

	list.add(new Divider());
	times = 20;
	while (times-- > 0) {
		list.add(new Msg("这是文本35435435453545354"));
	}

	//刷新到界面上
	adapter.display(list);
}
```

以上代码运行起来后效果如下：

![](http://img.blog.csdn.net/20160428151326317)

之后新增一个布局只需要新增一个对应的策略即可。

最后附上源码地址：

<http://download.csdn.net/detail/drkcore/9505492>