part of gui;

class Pop extends CJSElement {
	CJSElement doc;
    int width, height = 0;
    Rectangle view;

    Pop (CJSElement content, e) : super(new DivElement()) {
		setClass('ui-popUp');
		doc = new CJSElement(document.body);
	    view = doc.getRectangle();
		doc.addAction(clickPosition, 'mousedown.pop');
		set(content, e);
	}

	set (content, e) {
	    append(content).appendTo(doc);
	    width = getWidth();
	    height = getHeight();
	    Rectangle pos = getFixedPosition(e);
	    setStyle({'top': '${pos.top}px', 'left':'${pos.left}px'});
	    addClass('ui-popUp-active');
	    return this;
	}

	Rectangle getFixedPosition (MouseEvent e) {
		math.MutableRectangle pos = new math.MutableRectangle(0, 0, 0, 0);
	    pos.left = e.page.x;
	    pos.top = e.page.y;
	    var left_strech = pos.left + width,
	    	top_strech = pos.top + height,
	    	diff_hor = left_strech - view.width,
	    	diff_ver = top_strech - view.height;
		pos.left -= (diff_hor > 0)? diff_hor : 0;
		pos.top -= (diff_ver > 0)? diff_ver : 0;
	    return pos;
	}

	clickPosition (MouseEvent e) {
        Rectangle rect = getRectangle();
	    if (((rect.top < e.page.y)
	            && (e.page.y < (rect.top + rect.height)))
	                && ((rect.left < e.page.x)
	                    && (e.page.x < (rect.left + rect.width)))) {
	        return true;
	    }
	    return close();
	}

	close () {
	    doc.removeAction('mousedown.pop');
		remove();
	    return true;
	}
}

class Tab extends CJSElement {
    CJSElement tab_options, tab_options_inner, tab_content;
    Map views = new Map();
    Map view_cur;
    dynamic id_cur;

    Tab() : super(new DivElement()) {
		setClass('ui-tab');
        createHTML();
    }

    createHTML() {
        tab_options = new CJSElement(new DivElement())
            .setClass('ui-tab-options')
            .appendTo(this);
        tab_options_inner = new CJSElement(new DivElement())
            .setClass('ui-tab-options-inner')
            .appendTo(tab_options);
        tab_content = new CJSElement(new DivElement())
            .setClass('ui-tab-choice')
            .appendTo(this);
    }

    addTab (id, String title, o) {
        var choice = new CJSElement(new DivElement())
            .setClass('ui-tab-choice-inner')
            .appendTo(tab_content)
            .append(o);
        var option = new CJSElement(new AnchorElement())
            .setClass('ui-tab-link')
            .addAction((e) => activeTab(id))
            .appendTo(tab_options_inner);
        var span = new CJSElement(new SpanElement())
            .appendTo(option);
        if(title == null)
            option.hide();

        var view = {'option': option, 'cont': choice, 'title':span, 'form':o };
        view_cur = view;
        views[id] = view;
        setTabTitle(id, title);
        return this;
    }

    setTabTitle (id, [String title]) {
        var v = getTab(id);
        if(title == null) {
            v['hidden'] = true;
        } else {
            v['title'].dom.innerHtml = '';
            v['title'].append((title is String)? new Text(title) : title);
            v['hidden'] = false;
        }
        return this;
    }

    activeTab (id) {
        views.forEach((k, v) => _unactiveTab(v));
        var view = getTab(id);
        _activeTab(view);
        view_cur = view;
        id_cur = id;
        return this;
    }

    unactiveTab (id) {
        _unactiveTab(getTab(id));
        return this;
    }

    hideTab (id) {
        _hideTab(getTab(id));
        return this;
    }

    showTab (id) {
        _showTab(getTab(id));
        return this;
    }

    _unactiveTab(tab) {
        tab['option'].removeClass('active');
        tab['cont'].hide();
    }

    _activeTab(tab) {
        tab['option'].addClass('active');
        tab['cont'].show();
    }

    _hideTab(tab) {
        tab['option'].hide();
        tab['cont'].hide();
    }

    _showTab(tab) {
        tab['option'].show();
        if(tab == view_cur)
            tab['cont'].show();
    }

    fillParent () {
		var parent = new CJSElement(dom.parentNode);
        tab_content.setHeight(parent.getHeightInner() - tab_options.getHeight());
        return this;
    }

    getTab (id) {
        return views[id];
    }

    getCurId () {
        return id_cur;
    }

    tabsClear () {
		views.forEach((k, v) {
			v['title'].removeClass('save-do').removeClass('icon');
		});
    }

    tabChanged () {
        view_cur['title'].setClass('save-do icon');
    }
}

class DatePicker extends CJSElement {

	static List month_days = [31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	DateTime date;

	int cur_y, cur_m, cur_d, ch_m, ch_y;

	Function callBack;

	CJSElement domTbody, domMonth, domYear;

	CJSElement clicked;

	Queue<StreamSubscription> _l = new Queue();

	DatePicker (this.callBack) : super(new DivElement()) {
		setClass('ui-calendar');
	    date = new DateTime.now();
	    cur_y = date.year;
	    cur_m = date.month;
	    cur_d = date.day;
	    ch_m = cur_m;
	    ch_y = cur_y;
	    createHTML();
	}

	createHTML () {
		var e = new DivElement();
	    var nav = new CJSElement(new DivElement())..setClass('ui-cal-navigation').appendTo(this),
	    	nav_left = new CJSElement(new DivElement())..setClass('ui-cal-nav-left').appendTo(nav),
	        nav_right = new CJSElement(new DivElement())..setClass('ui-cal-nav-right').appendTo(nav);

		new action.Button()
	        .setIcon('controls-previous')
	        .addAction((e) {ch_m -= 1; set(); }, 'click')
	        .appendTo(nav_left);
	    var label_month = new CJSElement(new ParagraphElement())..appendTo(nav_left);
	    new action.Button()
	        .setIcon('controls-next')
	        .addAction((e) {ch_m += 1; set(); }, 'click')
	        .appendTo(nav_left);

	    new action.Button()
	        .setIcon('controls-previous')
	        .addAction((e) {ch_y -= 1; set(); }, 'click')
	        .appendTo(nav_right);
	    var label_year = new CJSElement(new ParagraphElement())..appendTo(nav_right);
	    new action.Button()
	        .setIcon('controls-next')
	        .addAction((e) {ch_y += 1; set(); }, 'click')
	        .appendTo(nav_right);

	    var table = new CJSElement(new TableElement())..appendTo(this);
	    var thead = new CJSElement(table.dom.createTHead())..appendTo(table),
	        tbody = new CJSElement(table.dom.createTBody())..appendTo(table);

	    var row = thead.dom.insertRow(-1);
	    for (var day = 0; day < 7; day++) {
	        var cell = row.insertCell(-1);
	        cell.className = Calendar.isWeekend(day)? 'weekend' : '';
	        cell.innerHtml = Calendar.day(day).substring(0,1);
	    }
	    for (var cell = 0; cell < 42; cell++) {
	        row = (cell%7==0)? tbody.dom.insertRow(-1) : row;
	        var c = row.insertCell(-1);
	        var mod = cell%7;
	        c.className = Calendar.isWeekend(mod)? 'weekend' : '';
	        c.append(new SpanElement());
	    }

	    var opt = new CJSElement(new DivElement())..setClass('ui-calendar-option').appendTo(this);
	    var opt_cur = new action.Button().setTitle(Calendar.textToday()).appendTo(opt),
	        opt_empty = new action.Button().setStyle({'float': 'right'}).setTitle(Calendar.textEmpty()).appendTo(opt);

	    if (callBack is Function) {
	        opt_cur.addAction((e) => callBack(new DateTime(cur_y, cur_m, cur_d)));
	        opt_empty.addAction((e) => callBack(null));
	    }

	    domMonth = label_month;
	    domYear = label_year;
	    domTbody = tbody;
	}

	set ([int y, int m, int d]) {
		ch_y = (y != null)? y : ch_y;
		ch_m = (m != null)? m : ch_m;
		int day_sel = d;
	    if(ch_m > 12) {
	        ch_m = 1;
	        ch_y += 1;
	    } else if(ch_m < 1) {
	        ch_m = 12;
	        ch_y -= 1;
	    }

	    var h = new DateTime(ch_y, ch_m, 1);
	    var firstDay = h.weekday;
	    month_days[1] = (((h.year % 100 != 0) && (h.year % 4 == 0)) || (h.year % 400 == 0))? 29 : 28;

	    var today = (ch_y == cur_y && ch_m == cur_m)? cur_d : null;

	    domMonth.dom.innerHtml = Calendar.month(ch_m - 1);
	    domYear.dom.innerHtml = ch_y.toString();

		while(_l.length > 0)
			_l.removeFirst().cancel();
	    var k = 0;
	    var click = (obj,[n]) {
	        if(obj.clicked != null)
	            obj.clicked.removeClass('selected');
	        if(n != null)
	            obj.clicked = new CJSElement(n).addClass('selected');
	    };
	    click(this);
	    for (var i = 0; i < 42; i++) {
	        var diff = i - (firstDay - Calendar.offset()),
	        	x = (diff > 0 && diff <= month_days[ch_m - 1])? diff : '',
	        	mod = i%7;
	        if (i!=0 && mod==0)
	            k++;
	        var cell = domTbody.dom.childNodes[k].cells[mod],
				span = cell.firstChild;
			span.className = (x==today)? 'active today' : 'active';
	        if(x == day_sel)
	            click(this, span);
			span.innerHtml = x.toString();
	        if (x != '') {
                _l.addLast(cell.onClick.listen((e) {
                    callBack(new DateTime(ch_y, ch_m, x));
                    click(this, cell.firstChild);
                }));
	        } else {
				span.className = '';
            }
        }
        return this;
    }
}

class DatePickerRange extends CJSElement{

	form.Input inputFrom, inputTo;
	form.Select choice;

	Function callBack;
	DatePicker c1, c2;

	DatePickerRange (this.callBack) : super(new DivElement()) {
		setClass('ui-calendar-picker-range');
		var domTop = new CJSElement(new DivElement())..setClass('ui-calendar-picker-range-top').appendTo(this),
			domBottom = new CJSElement(new DivElement())..setClass('ui-calendar-picker-range-bottom').appendTo(this);

	    choice = new form.Select();
	    inputFrom = new form.InputDate().noAction().setStyle({'float':'left', 'width':'75px', 'margin-left': '3px'});
	    inputTo = new form.InputDate().noAction().setStyle({'float':'left', 'width':'75px', 'margin-left': '3px'});
	    var done = new action.Button().setTitle(Calendar.textDone()).setStyle({'float':'right', 'margin':'0px'})
			.addAction((e) => callBack([inputFrom.getValue(), inputTo.getValue()]));

	    c1 = new DatePicker(inputFrom.setValue)..setStyle({'float': 'left'}).appendTo(domTop);
	    c2 = new DatePicker(inputTo.setValue)..setStyle({'float' :'right'}).appendTo(domTop);

	    choice.setStyle({'float':'left'}).addAction(setRange, 'change').addOption(0, Calendar.textChoosePeriod());
		int i = 1;
	    Calendar.ranges.forEach((r) {
	        choice.addOption(i, r['title']);
			i++;
	    });
	    choice.addAction((e) => e.stopPropagation(), 'mousedown');

	    domBottom.append(choice)
	            .append(inputFrom)
	            .append(inputTo)
	            .append(done);
	}

	setRange (e) {
	    var i = choice.getValue();
	    if (i > 0)
	        set(Calendar.ranges[i - 1]['method']());
	}

	set(List arr) {
		var date1 = (arr[0] == null)? new DateTime.now() : arr[0];
        var date2 = (arr[1] == null)? new DateTime.now() : arr[1];
		inputFrom.setValue(date1);
		inputTo.setValue(date2);
		c1.set(date1.year, date1.month, date1.day);
		c2.set(date2.year, date2.month, date2.day);
	}

}

class Tree {
	dynamic id;
    dynamic value;
    String _ref;
	String type;
    String clas = 'value';
    bool loadChilds = false;
    List childs = new List();

    int level = 0;
    String leftSide = '0';
    bool isLast = false;
    bool isOpen = false;
    bool isRendered = false;
    bool isLoading = false;

	Tree parent;
    TreeBuilder treeBuilder;

    TableElement dom;
	AnchorElement domNode, domValue;

    Tree (Map o) {
		id = o['id'];
        value = o['value'];
        type = o['type'];
        _ref = '$id:$type';
        loadChilds = o['loadchilds'];
        if (o['clas'] != null)
            clas += ' ${o['clas']}';
    }

    createHTML () {
        dom = new TableElement()..className = 'ui-tree';
        var row = dom.insertRow(0),
        	side = row.insertCell(-1),
        	node = row.insertCell(-1),
       		val = row.insertCell(-1);
        domNode = new AnchorElement();
        domValue = new AnchorElement();
        domNode.className = folderNode();
        var icon = folderImage();
        if(icon != null)
            clas += ' $icon icon';
        domValue.className = clas;
        domValue.append((value is String)? new Text(value) : value);
        domNode.onClick.listen((e) => operateNode(true));
        domValue.onMouseDown.listen((e) => clickedFolder());
        side.append(folderSide());
        node.append(domNode);
		val.append(domValue);
    }

    folderSide () {
        var width = 0;
        var div1 = new DivElement();
        for (int i=0, l=leftSide.split('').length; i<l; i++) {
            var div2 = new DivElement();
            div2.className = (leftSide[i] == '1')? 'vertline' : 'blank';
            width += 16;
            div1.append(div2);
        }
        div1.style.width = '${width}px';
        return div1;
    }

    folderImage () => treeBuilder.getIcon(this);

    folderNode () {
        if (isLoading)
            return 'loading';
        if (childs.length == 0 && parent == null && !loadChilds)
            return 'blank';
        if (isLast)
            if (childs.length > 0 || loadChilds)
                if (isOpen)
                    return (parent == null)? 'mfirstnode' : 'mlastnode';
                else
                    return (parent == null)? 'pfirstnode' : 'plastnode';
            else
                return 'lastnode';
        else
            if (childs.length > 0 || loadChilds)
                return (isOpen)? 'mnode' : 'pnode';
            else
                return 'node';
    }

    operateNode ([bool full = false]) {
        if (!isOpen)
            openChilds();
        else if (full)
            closeChilds();
        else
            return;
        setState();
    }

    clickedFolder () {
        var main = treeBuilder;
        if (main.current != null)
            main.current.domValue.className = main.current.clas;
        main.current = this;
        main.current.domValue.className = '$clas active';
        main.action(this);
    }

    setState () {
        isOpen = !isOpen;
        if (childs.length == 0)
            isOpen = false;
        domNode.className = folderNode();
    }

    openParents () {
        if (parent != null) {
            if (!parent.isOpen)
                parent.operateNode();
            parent.openParents();
        }
    }

    openChilds () {
        if (childs.length > 0) {
            for (var i = childs.length-1; i>=0; i--) {
                if (!childs[i].isRendered)
                    childs[i].renderObj();
                else
                    childs[i].dom.style.display = '';
                if (childs[i].isOpen)
                    childs[i].openChilds();
            }
        }
        else if (loadChilds)
            treeBuilder.loadTree(this);
    }

    closeChilds () {
        for (var i=0, l = childs.length; i<l; i++) {
            if (childs[i].isRendered)
                childs[i].dom.style.display = 'none';
            childs[i].closeChilds();
        }
    }

    removeChilds () {
        for (var i=0, l = childs.length; i<l; i++) {
            if (childs[i].isRendered) {
                childs[i].dom.remove();
                childs[i].isRendered = false;
            }
            childs[i].removeChilds();
        }
        childs = [];
    }

    renderObj () {
        createHTML();
        if (parent != null && parent.dom.nextElementSibling != null)
			treeBuilder.dom.insertBefore(dom, parent.dom.nextElementSibling);
        else
			treeBuilder.dom.append(dom);
        isRendered = true;
    }

    add (o) {
        var childFolder = new Tree(o);
        childs.add(childFolder);
        childFolder.parent = this;
        childFolder.treeBuilder = treeBuilder;
        return childFolder;
    }

    initialize (lev, lstNode, lftSide) {
        level = lev;
        isLast = lstNode;
        leftSide = lftSide;
        treeBuilder.indexOfObjects[_ref] = this;

        if (childs.length > 0) {
            if (treeBuilder.startOpen && level!=0)
                isOpen = true;
            level++;
            lftSide += (isLast)? "0" : "1";
            for (var i=0, l = childs.length; i<l; i++)
                if (i == childs.length - 1)
                    childs[i].initialize(level, true, lftSide);
                else
                    childs[i].initialize(level, false, lftSide);
        }
    }
}

class TreeCheck extends Tree {

	TreeCheck parent;
    bool checked = false;
    InputElement domInput;

	TreeCheck(o) : super(o);

    createHTML () {
        dom = new TableElement()..className = 'ui-tree';
        var row = dom.insertRow(0),
        	side = row.insertCell(-1),
        	node = row.insertCell(-1),
        	check = row.insertCell(-1),
        	val = row.insertCell(-1);
        domNode = new AnchorElement();
        domValue = new AnchorElement();
        domNode.className = this.folderNode();
        var icon = folderImage();
        if(icon != null)
            clas += ' $icon icon';
        domValue.className = clas;
        domValue.append((value is String)? new Text(value) : value);
        domNode.onClick.listen((e) => operateNode(true));
        domValue.onMouseDown.listen((e) => clickedFolder());
        side.append(folderSide());
        node.append(domNode);
        val.append(domValue);
		domInput = initChecked(check);
    }

    initChecked (container) {
        var input = new InputElement();
        input.type = 'checkbox';
        var checkObj = treeBuilder.checkObj;
        if (checkObj.contains(_ref) || (parent != null && parent.checked)) {
            input.checked = true;
            checked = true;
        }
        input.onClick.listen((e) => checkOperate());
        container.append(input);
        return input;
    }

    checkOperate () {
        if (!checked) {
            addCheck();
        }
        else {
            removeParentCheck();
            removeCheck();
        }
        treeBuilder.actionCheck(this);
    }

    addCheck () {
        checked = true;
        if (isRendered)
            domInput.checked = true;
        if (childs.length > 0)
            for (var i=0, l = childs.length; i<l; i++)
                childs[i].addCheck();
    }

    removeParentCheck () {
        if (parent != null) {
            parent.checked = false;
            if (parent.isRendered)
                parent.domInput.checked = false;
            parent.removeParentCheck();
        }
    }

    removeCheck () {
        checked = false;
        if (isRendered)
            domInput.checked = false;
        if (childs.length > 0)
            for (var i=0, l = childs.length; i<l; i++)
                childs[i].removeCheck();
    }

    add (o) {
        var childFolder = new TreeCheck(o);
        childs.add(childFolder);
        childFolder.parent = this;
        childFolder.treeBuilder = treeBuilder;
        return childFolder;
    }

}

class TreeChoice extends TreeCheck {

	TreeChoice(o) : super(o);

    clickedFolder () {}

    initChecked (container) {
        var input = new InputElement();
        input.type = 'checkbox';
        var checkObj = treeBuilder.checkObj;
        if (checkObj.contains(_ref)) {
            input.checked = true;
            checked = true;
        }
        input.onClick.listen((e) => checkOperate());
        container.append(input);
        return input;
    }

    checkOperate () {
        treeBuilder.main.removeCheck();
        checked = true;
        domInput.checked = true;
        treeBuilder.actionCheck(this);
        return true;
    }

    add (o) {
        var childFolder = new TreeChoice(o);
        childs.add(childFolder);
        childFolder.parent = this;
        childFolder.treeBuilder = treeBuilder;
        return childFolder;
    }
}

class TreeBuilder<E extends Tree> extends CJSElement {
    E main, current;
    Map indexOfObjects = new Map();
    List checkObj;
    bool checkSingle = false;
    bool startOpen = false;
    Map icons = new Map();
    Function action, actionCheck, load, valueTransform;

    TreeBuilder (o) : super (new DivElement()){
        action = (o['action'] is Function)? o['action'] : (_) {};
        actionCheck = (o['actionCheck'] is Function)? o['actionCheck'] : (_) {};
        load = o['load'];
        icons = (o['icons'] is Map)? o['icons']: {};
        checkObj = o['checkObj'];
        checkSingle = (o['checkSingle'] is bool)? o['checkSingle'] : false;
        valueTransform = (o['valueTransform'] is Function)? o['valueTransform'] : valueDefaultTransform;
        var init = {'value':o['value'], 'id':(o['id'] != null)? o['id'] : 0, 'type':o['type'], 'loadchilds': true};
        var folder = (checkObj != null)? ((checkObj is List && !checkSingle)? new TreeCheck(init) : new TreeChoice(init)) : new Tree(init);
		folder.treeBuilder = this;
        folder.initialize(0, true, '');
        folder.renderObj();
        main = folder;
    }

    getIcon (item) {
        if(icons.containsKey(item.type))
            return icons[item.type];
        return null;
    }

    getChecked () {
        checkObj = new List();
        setChecked(main);
        return checkObj;
    }

    setChecked (Tree folder) {
        for (var i=0, l = folder.childs.length; i<l; i++)
            if (folder.childs[i].checked)
                checkObj.add(folder.childs[i]._ref);
            else
                setChecked(folder.childs[i]);
    }

    loadTree (Tree item) {
        item.isLoading = true;
        item.domNode.className = item.folderNode();
        load(renderTree, item);
    }

    valueDefaultTransform(dynamic d) => d;

    renderTree (Tree item, Map data) {
        item.removeChilds();
        if(data.isNotEmpty) {
            var temp = {},
                childs = data['data'],
                meta = data['meta'];
            temp['item'] = item;
            for (var i = 0, l = childs.length; i < l; i++) {
                var cur = childs[i];
                temp[cur['r']] = temp[cur['p']].add(valueTransform(cur['d']));
            }
            if (meta == 'start_open') {
                startOpen = true;
            }
        }
        item.initialize(item.level, item.isLast, item.leftSide);
        item.isLoading = false;
        item.loadChilds = false;
        item.isOpen = false;
        item.operateNode();
    }

    refreshTree ([Tree item]) {
        item = (item != null)? item : main;
        if (item.isLoading)
            return;
        startOpen = false;
        loadTree(item);
    }
}