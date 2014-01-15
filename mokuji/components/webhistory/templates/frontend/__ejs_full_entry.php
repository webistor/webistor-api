
<div class="webhistory-entry" data-id="<%= id %>">

  <h3 class="title">
    <a href="<%= url %>" target="_blank">
      <%= title %>
    </a>
  </h3>

  <div class="url">
    <a href="<%= url %>" target="_blank">
      <%= url %>
    </a>
  </div>

  <div class="tags">
    <% if( typeof(tags) != 'undefined' ){ $.map(tags, function(tag){ %>
      <a href='#'>
        <%= tag.title %>
      </a>
    <% }) } %>
  </div>

  <div class="date">
    <label>Added</label>
    <%= dt_created %>
  </div>

  <div class="notes">
    <label>Notes</label>
    <%= notes %>
  </div>

</div>
