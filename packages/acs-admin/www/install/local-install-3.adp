<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<p> Done installing packages. </p>

<if @error_p@ true>
  <p> Unfortunately, we had some errors. Please check your server error log or contact your system administrator. </p>
</if>
<else>
  <p>
    <b>&raquo;</b> <a href="../server-restart">Please restart your server</a>
  </p>
</else>

