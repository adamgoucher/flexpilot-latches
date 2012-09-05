﻿/*
Copyright 2009, Matthew Eernisse (mde@fleegix.org) and Slide, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

package org.flex_pilot {
  import org.flex_pilot.FlexPilot;
  import org.flex_pilot.FPLogger;
  import flash.display.DisplayObject;
  import flash.display.DisplayObjectContainer;
  import flash.utils.*;

  public class FPLocator {
    // Stupid AS3 doesn't iterate over Object keys
    // in insertion order
    // null for the finder func means use the default
    // of findBySimpleAttr
    private static var locatorMap:Array = [
      ['name', null],
      ['id', null],
      ['link', FPLocator.findLink],
      ['label', null],
      ['htmlText', FPLocator.findHTML],
      ['automationName', null]
    ];
    private static var locatorMapObj:Object = {};
    private static var locatorMapCreated:Boolean = false;

    // This is the list of attrs we like to use for the
    // locators, in order of preference
    // FIXME: Need to add some regex fu for pawing through
    // text containers for Flash's janky anchor-tag impl
    private static var locatorLookupPriority:Array = [
      'automationName',
      'id',
      'name',
      'label',
      'htmlText'
    ];

    public static function init():void {
      for each (var arr:Array in FPLocator.locatorMap) {
        FPLocator.locatorMapObj[arr[0]] = arr[1];
      }
      FPLocator.locatorMapCreated = true;
    }

    public static function lookupDisplayObjectBool(
        params:Object):Boolean {

        var res:DisplayObject;
        res = FPLocator.lookupDisplayObject(params);
        if (res){
          return true;
        }
        return false;
    }

    public static function lookupDisplayObject(
        params:Object):DisplayObject {
        var res:DisplayObject;
        res = lookupDisplayObjectForContext(params, FlexPilot.getContext());
        if (!res && FlexPilot.contextIsApplication()) {
          res = lookupDisplayObjectForContext(params, FlexPilot.getStage());
        }

        return res;
    }

    public static function lookupDisplayObjectForContext(
        params:Object, obj:*):DisplayObject {

      var locators:Array = [];
      var queue:Array = [];

      var checkFPLocatorChain:Function = function (
          item:*, pos:int):DisplayObject {
        var map:Object = FPLocator.locatorMapObj;
        var loc:Object = locators[pos];
        // If nothing specific exists for that attr, use the basic one
        var finder:Function = map[loc.attr] || FPLocator.findBySimpleAttr;
        var next:int = pos + 1;
        if (!!finder(item, loc.attr, loc.val)) {
          // Move to the next locator in the chain
          // If it's the end of the chain, we have a winner
          if (next == locators.length) {
            return item;
          }
          // Otherwise recursively check the next link in
          // the locator chain
          var count:int = 0;
          if (item is DisplayObjectContainer) {
            count = item.numChildren;
          }
          if (count > 0) {
            var index:int = 0;
            while (index < count) {
              var kid:DisplayObject = item.getChildAt(index);
              var res:DisplayObject = checkFPLocatorChain(kid, next);
              if (res) {
                return res;
              }
              index++;
            }
          }
        }
        return null;
      };

      var str:String = normalizeFPLocator(params);
      locators = parseFPLocatorChainExpresson(str);

      queue.push(obj);
      while (queue.length) {
        // Otherwise grab the next item in the queue
        var item:* = queue.shift();
        // Append any kids to the end of the queue
        if (item is DisplayObjectContainer) {
          var count:int = item.numChildren;
          var index:int = 0;
          while (index < count) {
            var kid:DisplayObject = item.getChildAt(index);
            queue.push(kid);
            index++;
          }
        }
        var res:DisplayObject = checkFPLocatorChain(item, 0);
        // If this is a full match, we're done
        if (res) {
          return res;
        }
      }
      throw new Error("The chain '" + str +"' was not found.")
      return null;
    }

    private static function parseFPLocatorChainExpresson(
        exprStr:String):Array {
      var locators:Array = [];
      var expr:Array = exprStr.split('/');
      var arr:Array;
      for each (var item:String in expr) {
        arr = item.split(':');
        locators.push({
          attr: arr[0],
          val: arr[1]
        });
      }
      return locators;
    }

    private static function normalizeFPLocator(params:Object):String {
      if ('chain' in params) {
        return params.chain;
      }
      else {
        var map:Object = FPLocator.locatorMap;
        var attr:String;
        var val:*;
        // FPLocators have an order of precedence -- ComboBox will
        // have a name/id, and its sub-options will have label
        // Make sure to do name-/id-based lookups first, label last
        for each (var item:Array in map) {
          if (item[0] in params) {
            attr = item[0];
            val = params[attr];
            break;
          }
        }
        return attr + ':' + val;
      }
    }

    // Default locator for all basic key/val attr matches
    private static function findBySimpleAttr(
        obj:*, attr:String, val:*):Boolean {
      //if we receive a simple attr with an asterix
      //we create a regex allowing for wildcard strings
      if (val.indexOf("*") != -1) {
        if (attr in obj) {
          //repalce wildcards with any character match
          var valRegExp:String = val.replace(new RegExp("\\*", "g"), "(.*)");
          //force a beginning and end
          valRegExp = "^"+valRegExp +"$";
          var wildcard:RegExp = new RegExp(valRegExp);
          var result:Object = wildcard.exec(obj[attr]);
          return !!(result != null);
        }
      }
      return !!(attr in obj && obj[attr] == val);
    }

    // Custom locator for links embedded in htmlText
    private static function findLink(
        obj:*, attr:String, val:*):Boolean {
      var res:Boolean = false;
      if ('htmlText' in obj) {
        res = !!locateLinkHref(val, obj.htmlText);
      }
      return res;
    }

    // Custom locator for links embedded in htmlText
    private static function findHTML(
        obj:*, attr:String, val:*):Boolean {
      var res:Boolean = false;
      if ('htmlText' in obj) {
        var text:String = FPLocator.cleanHTML(obj.htmlText);
        return val == text;
      }
      return res;
    }

    // Used by the custom locator for links, above
    public static function locateLinkHref(linkText:String,
        htmlText:String):String {
      var pat:RegExp = /(<a.+?>)([\s\S]*?)(?:<\/a>)/gi;
      var res:Array;
      var linkPlain:String = '';
      while (!!(res = pat.exec(htmlText))) {
        // Remove HTML tags and linebreaks; and trim
        linkPlain = FPLocator.cleanHTML(res[2]);
        if (linkPlain == linkText) {
          var evPat:RegExp = /href="event:(.*?)"/i;
          var arr:Array = evPat.exec(res[1]);
          if (!!(arr && arr[1])) {
            return arr[1];
          }
          else {
            return '';
          }
        }
      }
      return '';
    }

    private static function cleanHTML(markup:String):String {
      return markup.replace(/<.+?>/g, '').replace(
          /\s+/g, ' ').replace(/^ | $/g, '');
    }

    // Generates a chained-locator expression for the clicked-on item
    public static function generateLocator(item:*, ...args):String {
      var strictLocators:Boolean = FlexPilot.config.strictLocators;
      if (args.length) {
        strictLocators = args[0];
      }
      var expr:String = '';
      var exprArr:Array = [];
      var attr:String;
      var attrVal:String;
      // Verifies the property exists, and that the child can
      // be found from the parent (in some cases there is a parent
      // which does not have the item in its list of children)
      var weHaveAWinner:Function = function (item:*, attr:String):Boolean {
        var winner:Boolean = false;
        // Get an attribute that actually has a value
        if (usableAttr(item, attr)) {
          // Make sure that the parent can actually see
          // this item in its list of children
          var par:* = item.parent;
          var count:int = 0;
          if (par is DisplayObjectContainer) {
            count = par.numChildren;
          }
          if (count > 0) {
            var index:int = 0;
            while (index < count) {
              var kid:DisplayObject = par.getChildAt(index);
              if (kid == item) {
                winner = true;
                break;
              }
              index++;
            }
          }
        }
        return winner;
      };
      var usableAttr:Function = function (item:*, attr:String):Boolean {
        // Item has to have an attribute of that name
        if (!(attr in item)) {
          return false;
        }
        // Attribute's value cannot be null
        if (!item[attr]) {
          return false;
        }
        // If strict locators are on, don't accept an auto-generated
        // 'name' attribute ending in a number -- e.g., TextField05
        // These are often unreliable as locators
        if (strictLocators &&
            attr == 'name' && /\d+$/.test(item[attr])) {
          return false;
        }
        return true;
      };
      var isValidLookup:Function = function (exprArr:Array):Boolean {
        expr = exprArr.join('/');
        // Make sure that the expression actually looks up a
        // valid object
        var validLookup:DisplayObject = lookupDisplayObject({
          chain: expr
        });
        return !!validLookup;
      };
      // Attrs to look for, ordered by priority
      var locatorPriority:Array = FPLocator.locatorLookupPriority;
      do {
        // Try looking up a value for each attribute in order
        // of preference
        for each (attr in locatorPriority) {
          // If we find one of the lookuup keys, we may have a winner
          if (weHaveAWinner(item, attr)) {
            // Prepend onto the locator expression, then check to
            // see if the chain still results in a valid lookup
            attrVal = attr == 'htmlText' ?
                FPLocator.cleanHTML(item[attr]) : item[attr];
            exprArr.unshift(attr + ':' + attrVal);
            // If this chain looks up an object correct, keeps going
            if (isValidLookup(exprArr)) {
              break;
            }
            // Otherwise throw out this attr/value pair and keep
            // trying
            else {
              exprArr.shift();
            }
          }
        }
        item = item.parent;
      } while (item.parent && !(item.parent == FlexPilot.getContext() ||
          item.parent == FlexPilot.getStage()))
      if (exprArr.length) {
        expr = exprArr.join('/');
        return expr;
      }
      else {
        return null;
      }
    }
  }
}
