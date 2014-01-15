
<div class="webhistory-entry" data-id="<%= id %>">

  <h3 class="title">
    <a href="<%= url %>" target="_blank">
      <%= title %>
    </a>
  </h3>

  <div class="url">
    <a href="<%= url %>" target="_blank" class="link">
      <%= url %>
    </a>
  </div>

  <div class="tags">
    <% if( typeof(tags) != 'undefined' ){ $.map(tags, function(tag){ %>
      <a href='#' class="tag orange">
        <%= tag.title %>
      </a>
    <% }) } %>
  </div>

  <div class="actions">
    <a href="?id=<%= id %>" class="edit">
      Edit
    </a>
    <a href="#" class="delete">
      Delete
    </a>
  </div>

</div>

