(function($, global){
  
  ////////////
  // JSLite //
  ////////////
  var Class = JSLite.Class
    , ClassFactory = JSLite.ClassFactory;
  
  //////////
  // GUID //
  //////////
  function guid(){
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
      return v.toString(16);
    });
  }
  


  ///////////
  // Model //
  ///////////
  

  /**
   * The EntryModel class.
   */
  var EntryModel = (new Class)

  /**
   * Construct an EntryController.
   */
  .construct(function(id, data, fresh){

    this.name = 'entry';
    this.fresh = fresh||false;
    this.id = id || guid();
    this.data = data || {};

  })

  .statics({

  })

  .members({

    id: null,
    data: null,

    /**
     * Get data.
     *
     * @param {string} key The key to look for.
     *
     * @return {mixed} The matched data.
     */
    get: function(key){
      return this.data[key];
    },
    
    /**
     * Set data.
     *
     * @param {string} key The key to store the value under.
     * @param {mixed} value The value to store.
     *
     * @chainable
     */
    set: function(key, value){
      this.data[key] = value;
      return this;
    },
    
    /**
     * Set multiple nodes.
     *
     * @param {object} map A map of keys and values to set.
     *
     * @chainable
     */
    setAll: function(map){
      $.extend(this.data, map);
      return this;
    },
    
    /**
     * Fetch the resource from the server.
     *
     * @return {jQuery.Deferred.Promise} The promise object handling the AJAX callbacks.
     */
    fetch: function(){
      return request(GET, this.name);
    },

    /**
     * Stores the resource on the server.
     *
     * @return {jQuery.Deferred.Promise} The promise object handling the AJAX callbacks.
     */
    save: function(){
      return request((this.fresh ? POST : PUT), this.name, this.getData()).done(this.proxy(function(data){
        this.data = data;
        this.fresh = false;
      }));
    },
    
    /**
     * Returns the given function in a wrapper that will execute the function in the context of this object.
     *
     * @param {function} func The function to be wrapped.
     *
     * @return {function} The wrapped function.
     */
    proxy: function(func){
      $.proxy(func, this);
    },
    
    /**
     * Return the models data.
     *
     * @return {object}
     */
    getData: function(){
      return this.data;
    }

  })

  .finalize();


  
  ////////////////
  // Controller //
  ////////////////

  /**
   * The EntryListController class.
   */
  var EntryListController = (new Class)
    
  /**
   * Construct an EntryListController.
   *
   * @param {EntryListModel} model The model this controller will work with.
   * @param {HTMLElement} element The HTML element to work with.
   */
  .construct(function(settings){

    var entrylistcontroller = this
      , el_entry = $('.webhistory-entry');

    //Load entries from database.
    entrylistcontroller.loadEntries(settings.search)

    //Render entries.
    .done( entrylistcontroller.renderEntries );

  })

  //Add static members.
  .statics({
    entries: {}
  })
  
  //Define members for the EntryListController class.
  .members({
    
    loadEntries: function(search){

      var entrylistcontroller = EntryListController
        , el_entry_list = $('#js-webhistory-entry-list');

      el_entry_list.empty();
      el_entry_list.text('Loading...');

      //Get entries.
      return $.rest('GET', '?rest=webhistory/entries/'+search)

      //Save entries in entries variable.
      .done(function(entries){
        entrylistcontroller.entries = entries;
      });

    },

    renderEntries: function(){

      var entrylistcontroller = EntryListController
        , el_entry_list = $('#js-webhistory-entry-list')
        , el_sidebar = $('#js-webhistory-sidebar')
        , el_entry = $('.webhistory-entry');

      //Empty container.
      el_entry_list.empty();

      //Loop entries and fill container.
      $.each(entrylistcontroller.entries, function(i){
        
        var entrylistcontroller = EntryListController
          , data = entrylistcontroller.entries[i]
          , model = new EntryModel(data.id, data)
          , tmpl = new EJS({url: '?section=webhistory/ejs_list_entry'})
          , el_entry;

        //Fill entry template with data.
        $(tmpl.render(model.data))

          //Append entry to item list.
          .appendTo(el_entry_list)

          //Bind events on entry.
          .on('click', function(e){

            tmpl = new EJS({url: '?section=webhistory/ejs_full_entry'});

            //Fill sidebar template with data.
            el_sidebar.html( $(tmpl.render(model.data)) );

          })

          .find('.actions .delete')

            .on('click', function(e){

              e.preventDefault();

              if(confirm('Are you sure?')){
                
                $(this).closest('.webhistory-entry').slideUp(function(){
                  $(this).remove();
                });
                
                $.ajax('?action=webhistory/delete_item&entry_id='+model.data.id);
              }

            });

      });

    }

  })
  
  //Finalize the EntryListController class.
  .finalize();

  
  
  
  ////////////////
  // Webhistory //
  ////////////////
  
  /**
   * The main class and API.
   */
  var Webhistory = (new Class)
  
  /**
   * Construct the Webhistory class.
   *
   * @param {object} settings A map of settings.
   * 
   * @return {Webhistory}
   */
  .construct(function(settings){

    //Initiate variables.
    var WH = this;

    //Init controllers.
    new EntryListController(settings);

  })
  
  .members({
    
    /**
     * Register a template to the pool.
     *
     * @param {Template} template The instance of template to register.
     *
     * @chainable
     */
    registerTemplate: function(template){
      this.templates.push(template);
      return this;
    }
    
  })
  
  .finalize();
  
  
  
  /////////////
  // Exports //
  /////////////
  
  global.Webhistory = Webhistory;


})(jQuery, window);
