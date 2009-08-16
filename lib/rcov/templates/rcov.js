function toggleCode( id ) {
  if ( document.getElementById )
  elem = document.getElementById( id );
  else if ( document.all )
  elem = eval( "document.all." + id );
  else
  return false;

  elemStyle = elem.style;

  if ( elemStyle.display != "block" ) {
    elemStyle.display = "block"
  } else {
    elemStyle.display = "none"
  }

  return true;
}

// Make cross-references hidden by default
document.writeln( "<style type=\"text/css\">span.cross-ref { display: none }</style>" )

/*

	Copyright (c) 2006 Andrew Tetlaw 
	http://tetlaw.id.au/view/blog/table-sorting-with-prototype/
	
	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy,
	modify, merge, publish, distribute, sublicense, and/or sell copies
	of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
	BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
	ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
		
*/

var SortableTable = {
  init : function(elm, o){
    var table = $(elm);
    if(table.tagName != "TABLE") return;
    if(!table.id) table.id = "sortable-table-" + SortableTable._count++;
    Object.extend(SortableTable.options, o || {} );
    var doscroll = (SortableTable.options.tableScroll == 'on' || (SortableTable.options.tableScroll == 'class' && table.hasClassName(SortableTable.options.tableScrollClass)));
    var sortFirst;
    var cells = SortableTable.getHeaderCells(table);
    cells.each(function(c){
      c = $(c);
      if(!doscroll) {
        Event.observe(c, 'click', SortableTable._sort.bindAsEventListener(c));
        c.addClassName(SortableTable.options.columnClass);
      }
      if(c.hasClassName(SortableTable.options.sortFirstAscendingClass) || c.hasClassName(SortableTable.options.sortFirstDecendingClass)) sortFirst = c;
    });

    if(sortFirst) {
      if(sortFirst.hasClassName(SortableTable.options.sortFirstAscendingClass)) {
        SortableTable.sort(table, sortFirst, 1);
      } else {
        SortableTable.sort(table, sortFirst, -1);
      }
    } else { // just add row stripe classes
      var rows = SortableTable.getBodyRows(table);
      rows.each(function(r,i) {
        SortableTable.addRowClass(r,i);
      });
    }
    if(doscroll) SortableTable.initScroll(table);
  },
  initScroll : function(elm){
    var table = $(elm);
    if(table.tagName != "TABLE") return;
    table.addClassName(SortableTable.options.tableScrollClass);
    
    var w = table.getDimensions().width;
    
    table.setStyle({
      'border-spacing': '0',
      'table-layout': 'fixed',
      width: w + 'px'
    });
    
    var cells = SortableTable.getHeaderCells(table);
    cells.each(function(c,i){
      c = $(c);
      var cw = c.getDimensions().width;
      c.setStyle({width: cw + 'px'});
      $A(table.tBodies[0].rows).each(function(r){
        $(r.cells[i]).setStyle({width: cw + 'px'});
      })
    })	
    
    // Fixed Head
    var head = (table.tHead && table.tHead.rows.length > 0) ? table.tHead : table.rows[0];
    var hclone = head.cloneNode(true);
    
    var hdiv = $(document.createElement('div'));
    hdiv.id = table.id + '-head';
    table.parentNode.insertBefore(hdiv, table);
    hdiv.setStyle({
      overflow: 'hidden'
    });
    var htbl = $(document.createElement('table'));
    htbl.setStyle({
      'border-spacing': '0',
      'table-layout': 'fixed',
      width: w + 'px'
    });
    hdiv.appendChild(htbl);
    hdiv.addClassName('scroll-table-head');
    
    table.removeChild(head);
    htbl.appendChild(hclone);
    
    cells = SortableTable.getHeaderCells(htbl);
    cells.each(function(c){
      c = $(c);
      Event.observe(c, 'click', SortableTable._sortScroll.bindAsEventListener(c));
      c.addClassName(SortableTable.options.columnClass);
    });	

    // Table Body
    var cdiv = $(document.createElement('div'));
    cdiv.id = table.id + '-body';
    table.parentNode.insertBefore(cdiv, table);
    cdiv.setStyle({
      overflow: 'auto'
    });
    cdiv.appendChild(table);
    cdiv.addClassName('scroll-table-body');
    
    hdiv.scrollLeft = 0;
    cdiv.scrollLeft = 0;

    Event.observe(cdiv, 'scroll', SortableTable._scroll.bindAsEventListener(table), false);
    if(table.offsetHeight - cdiv.offsetHeight > 0){
      cdiv.setStyle({width:(cdiv.getDimensions().width + 16) + 'px'})
    }
  },
  _scroll: function(){
        $(this.id + '-head').scrollLeft  = $(this.id + '-body').scrollLeft;
    },
  _sort : function(e) {
    SortableTable.sort(null, this);
  },
  _sortScroll : function(e) {	
    var hdiv = $(this).up('div.scroll-table-head');
    var id = hdiv.id.match(/^(.*)-head$/);
    SortableTable.sort($(id[1]), this);
  },
  sort : function(table, index, order) {
    var cell;
    if(typeof index == 'number') {
      if(!table || (table.tagName && table.tagName != "TABLE")) return;
      index = Math.min(table.rows[0].cells.length, index);
      index = Math.max(1, index);
      index -= 1;
      cell = (table.tHead && table.tHead.rows.length > 0) ? $(table.tHead.rows[table.tHead.rows.length-1].cells[index]) : $(table.rows[0].cells[index]);
    } else {
      cell = $(index);
      table = table ? $(table) : table = cell.up('table');
      index = SortableTable.getCellIndex(cell)
    }
    var op = SortableTable.options;
    
    if(cell.hasClassName(op.nosortClass)) return;	
    order = order ? order : (cell.hasClassName(op.descendingClass) ? 1 : -1);

    var hcells = SortableTable.getHeaderCells(null, cell);
    $A(hcells).each(function(c,i){
      c = $(c);
      if(i == index) {
        if(order == 1) {
          c.removeClassName(op.descendingClass);
          c.addClassName(op.ascendingClass);
        } else {
          c.removeClassName(op.ascendingClass);
          c.addClassName(op.descendingClass);
        }
      } else {
        c.removeClassName(op.ascendingClass);
        c.removeClassName(op.descendingClass);
      }
    });

    var rows = SortableTable.getBodyRows(table);
    var datatype = SortableTable.getDataType(cell,index,table);
    rows.sort(function(a,b) {
      return order * SortableTable.types[datatype](SortableTable.getCellText(a.cells[index]),SortableTable.getCellText(b.cells[index]));
    });

    rows.each(function(r,i) {
      table.tBodies[0].appendChild(r);
      SortableTable.addRowClass(r,i);
    });
  },
  types : {
    number : function(a,b) {
      // This will grab the first thing that looks like a number from a string, so you can use it to order a column of various srings containing numbers.
      var calc = function(v) {
        v = parseFloat(v.replace(/^.*?([-+]?[d]*.?[d]+(?:[eE][-+]?[d]+)?).*$/,"$1"));
        return isNaN(v) ? 0 : v;
      }
      return SortableTable.compare(calc(a),calc(b));
    },
    text : function(a,b) {
      return SortableTable.compare(a ? a.toLowerCase() : '', b ? b.toLowerCase() : '');
    },
    casesensitivetext : function(a,b) {
      return SortableTable.compare(a,b);
    },
    datasize : function(a,b) {
      var calc = function(v) {
        var r = v.match(/^([-+]?[d]*.?[d]+([eE][-+]?[d]+)?) ?([k|m|g|t]?b)?/i);
        var b = r[1] ? Number(r[1]).valueOf() : 0;
        var m = r[3] ? r[3].substr(0,1).toLowerCase() : '';
        switch(m) {
          case  'k':
            return b * 1024;
            break;
          case  'm':				
            return b * 1024 * 1024;
            break;
          case  'g':
            return b * 1024 * 1024 * 1024;
            break;
          case  't':
            return b * 1024 * 1024 * 1024 * 1024;
            break;
        }
        return b;
      }
      return SortableTable.compare(calc(a),calc(b));
    },
    'date-au' : function(a,b) {
      var calc = function(v) {
        var r = v.match(/^(d{2})\\/(d{2})\\/(d{4}) ?(?:(d{1,2}):(d{2})(?::(d{2}))? ?([a|p]?m?))?/i);
        var yr_num = r[3];
        var mo_num = parseInt(r[2])-1;
        var day_num = r[1];
        var hr_num = r[4] ? r[4] : 0;
        if(r[7] && r[7].toLowerCase().indexOf('p') != -1) {
          hr_num = parseInt(r[4]) + 12;
        }
        var min_num = r[5] ? r[5] : 0;
        var sec_num = r[6] ? r[6] : 0;
        return new Date(yr_num, mo_num, day_num, hr_num, min_num, sec_num, 0).valueOf();
      }
      return SortableTable.compare(a ? calc(a) : 0, b ? calc(b) : 0);
    },
    'date-us' : function(a,b) {
      var calc = function(v) {
        var r = v.match(/^(d{2})\\/(d{2})\\/(d{4}) ?(?:(d{1,2}):(d{2})(?::(d{2}))? ?([a|p]?m?))?/i);
        var yr_num = r[3];
        var mo_num = parseInt(r[1])-1;
        var day_num = r[2];
        var hr_num = r[4] ? r[4] : 0;
        if(r[7] && r[7].toLowerCase().indexOf('p') != -1) {
          hr_num = parseInt(r[4]) + 12;
        }
        var min_num = r[5] ? r[5] : 0;
        var sec_num = r[6] ? r[6] : 0;
        return new Date(yr_num, mo_num, day_num, hr_num, min_num, sec_num, 0).valueOf();
      }
      return SortableTable.compare(a ? calc(a) : 0, b ? calc(b) : 0);
    },
    'date-eu' : function(a,b) {
      var calc = function(v) {
        var r = v.match(/^(d{2})-(d{2})-(d{4})/);
        var yr_num = r[3];
        var mo_num = parseInt(r[2])-1;
        var day_num = r[1];
        return new Date(yr_num, mo_num, day_num).valueOf();
      }
      return SortableTable.compare(a ? calc(a) : 0, b ? calc(b) : 0);
    },
    'date-iso' : function(a,b) {
      // http://delete.me.uk/2005/03/iso8601.html ROCK!
      var calc = function(v) {
          var d = v.match(/([d]{4})(-([d]{2})(-([d]{2})(T([d]{2}):([d]{2})(:([d]{2})(.([d]+))?)?(Z|(([-+])([d]{2}):([d]{2})))?)?)?)?/);
      
          var offset = 0;
          var date = new Date(d[1], 0, 1);
      
          if (d[3]) { date.setMonth(d[3] - 1) ;}
          if (d[5]) { date.setDate(d[5]); }
          if (d[7]) { date.setHours(d[7]); }
          if (d[8]) { date.setMinutes(d[8]); }
          if (d[10]) { date.setSeconds(d[10]); }
          if (d[12]) { date.setMilliseconds(Number("0." + d[12]) * 1000); }
          if (d[14]) {
              offset = (Number(d[16]) * 60) + Number(d[17]);
              offset *= ((d[15] == '-') ? 1 : -1);
          }
          offset -= date.getTimezoneOffset();
          if(offset != 0) {
            var time = (Number(date) + (offset * 60 * 1000));
            date.setTime(Number(time));
          }
        return date.valueOf();
      }
      return SortableTable.compare(a ? calc(a) : 0, b ? calc(b) : 0);

    },
    date : function(a,b) { // must be standard javascript date format
      if(a && b) {
        return SortableTable.compare(new Date(a),new Date(b));
      } else {
        return SortableTable.compare(a ? 1 : 0, b ? 1 : 0);
      }
      return SortableTable.compare(a ? new Date(a).valueOf() : 0, b ? new Date(b).valueOf() : 0);
    },
    time : function(a,b) {
      var d = new Date();
      var ds = d.getMonth() + "/" + d.getDate() + "/" + d.getFullYear() + " "
      return SortableTable.compare(new Date(ds + a),new Date(ds + b));
    },
    currency : function(a,b) {
      a = parseFloat(a.replace(/[^-d.]/g,''));
      b = parseFloat(b.replace(/[^-d.]/g,''));
      return SortableTable.compare(a,b);
    }
  },
  compare : function(a,b) {
    return a < b ? -1 : a == b ? 0 : 1;
  },
  detectors : $A([
    {re: /[d]{4}-[d]{2}-[d]{2}(?:T[d]{2}:[d]{2}(?::[d]{2}(?:.[d]+)?)?(Z|([-+][d]{2}:[d]{2})?)?)?/, type : "date-iso"}, // 2005-03-26T19:51:34Z
    {re: /^sun|mon|tue|wed|thu|fri|sat, d{1,2} jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec d{4}(?: d{2}:d{2}(?::d{2})?(?: GMT(?:[+-]d{4})?)?)?/i, type : "date"}, //Mon, 18 Dec 1995 17:28:35 GMT 
    {re: /^d{2}-d{2}-d{4}/i, type : "date-eu"},
    {re: /^d{2}\\/d{2}\\/d{4} ?(?:d{1,2}:d{2}(?::d{2})? ?[a|p]?m?)?/i, type : "date-au"},
    {re: /^d{1,2}:d{2}(?::d{2})?(?: [a|p]m)?$/i, type : "time"},
    {re: /^[$£¥€¤]/, type : "currency"}, // dollar,pound,yen,euro,generic currency symbol
    {re: /^[-+]?[d]*.?[d]+(?:[eE][-+]?[d]+)? ?[k|m|g|t]b$/i, type : "datasize"},
    {re: /^[-+]?[d]*.?[d]+(?:[eE][-+]?[d]+)?/, type : "number"},
    {re: /^[A-Z]+$/, type : "casesensitivetext"},
    {re: /.*/, type : "text"}
  ]),
  addSortType : function(name, sortfunc) {
    SortableTable.types[name] = sortfunc;
  },
  addDetector : function(rexp, name) {
    SortableTable.detectors.unshift({re:rexp,type:name});
  },
  getBodyRows : function(table) {
    table = $(table);
    return (table.hasClassName(SortableTable.options.tableScrollClass) || table.tHead && table.tHead.rows.length > 0) ? 
          $A(table.tBodies[0].rows) : $A(table.rows).without(table.rows[0]);
  },
  addRowClass : function(r,i) {
    r = $(r)
    r.removeClassName(SortableTable.options.rowEvenClass);
    r.removeClassName(SortableTable.options.rowOddClass);
    r.addClassName(((i+1)%2 == 0 ? SortableTable.options.rowEvenClass : SortableTable.options.rowOddClass));
  },
  getHeaderCells : function(table, cell) {
    if(!table) table = $(cell).up('table');
    return $A((table.tHead && table.tHead.rows.length > 0) ? table.tHead.rows[table.tHead.rows.length-1].cells : table.rows[0].cells);
  },
  getCellIndex : function(cell) {
    return $A(cell.parentNode.cells).indexOf(cell);
  },
  getCellText : function(cell) {
    if(!cell) return "";
    return cell.textContent ? cell.textContent : cell.innerText;
  },
  getDataType : function(cell,index,table) {
    cell = $(cell);
    var t = cell.classNames().detect(function(n){ // first look for a data type classname on the heading row cell
      return (SortableTable.types[n]) ? true : false;
    });
    if(!t) {
      var i = index ? index : SortableTable.getCellIndex(cell);
      var tbl = table ? table : cell.up('table')
      cell = tbl.tBodies[0].rows[0].cells[i]; // grab same index cell from second row to try and match data type
      t = SortableTable.detectors.detect(function(d){return d.re.test(SortableTable.getCellText(cell));})['type'];
    }
    return t;
  },
  setup : function(o) {
    Object.extend(SortableTable.options, o || {} )
     //in case the user added more types/detectors in the setup options, we read them out and then erase them
     // this is so setup can be called multiple times to inject new types/detectors
    Object.extend(SortableTable.types, SortableTable.options.types || {})
    SortableTable.options.types = {};
    if(SortableTable.options.detectors) {
      SortableTable.detectors = $A(SortableTable.options.detectors).concat(SortableTable.detectors);
      SortableTable.options.detectors = [];
    }
  },
  options : {
    autoLoad : true,
    tableSelector : ['table.sortable'],
    columnClass : 'sortcol',
    descendingClass : 'sortdesc',
    ascendingClass : 'sortasc',
    nosortClass : 'nosort',
    sortFirstAscendingClass : 'sortfirstasc',
    sortFirstDecendingClass : 'sortfirstdesc',
    rowEvenClass : 'roweven',
    rowOddClass : 'rowodd',
    tableScroll : 'class',   // off | on | class;
    tableScrollClass : 'scroll'
  },
  _count : 0,
  load : function() {
    if(SortableTable.options.autoLoad) {
      $A(SortableTable.options.tableSelector).each(function(s){
        $$(s).each(function(t) {
          SortableTable.init(t, {tableScroll : SortableTable.options.tableScroll});
        });
      });
    }
  }
}

Event.observe(window, 'load', SortableTable.load);

