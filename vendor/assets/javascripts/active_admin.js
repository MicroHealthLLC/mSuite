//= require active_admin/base
//= require activeadmin_addons/all
//= require jquery_ujs
//= require activestorage

jQuery(function($) {

  // settings page
  if ($("#settings_container").is(":visible"))
  {
    const settings_vue = new Vue({
      el: "#settings_container",
      data() {
        return {
          currentTab: 1,
          isEditing: false,
          loading: true,
          settings: {
            office365_key: '',
            office365_secret: '',
            google_oauth_key: '',
            google_oauth_secret: '',
            google_recaptcha_site_key: '',
            host_url: '',
            beta_status: true,
            beta_url: '',
            public_url: '',
            privacy_url: '',
            about_url: '',
            terms_url: '',
            failed_password_attempts: 0,
            lockout_period: 0,
            permanent_lock: 0
          }
        }
      },
      mounted() {
        this.fetchSettings();
      },
      computed: {
        textType() {
          return this.isEditing ? 'text' : 'password';
        }
      },
      methods: {
        submitSettings() {
          $.ajax({
            type: "POST",
            url: "/api/settings.json",
            data: { settings: this.settings },
            success: function(msg){
              alert( "Data Saved");
              window.location.href = "/admin/settings";
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
              alert(XMLHttpRequest.responseJSON.join('\n'))
            }
          });
        },
        fetchSettings() {
          $.get("/api/settings.json", (data) => {
            for (let key in this.settings) {
              this.settings[key] = data[key];
            }
            this.loading = false;
          }).fail(function() {
            alert("Error fetching settings")
          })
        }
      },
      template: `<div>
        <button class="edit-creds" :class="{'vue__disabled': isEditing}" @click.stop="isEditing=true">Edit</button>
        <form v-if="!loading" class="formtastic settings" @submit.prevent="submitSettings">
          <div class="tabs ui-tabs ui-corner-all ui-widget ui-widget-content">
            <ul class="nav nav-tabs ui-tabs-nav ui-corner-all ui-helper-reset ui-helper-clearfix ui-widget-header" role="tablist">
              <li role="tab" tabindex="0" class="ui-tabs-tab ui-corner-top ui-state-default ui-tab" aria-controls="office365" aria-labelledby="ui-id-1" :class="{'ui-tabs-active ui-state-active': currentTab == 1}"><a @click.stop.prevent="currentTab = 1" role="presentation" tabindex="-1" class="ui-tabs-anchor" id="ui-id-1">Office 365</a></li>
              <li role="tab" tabindex="-1" class="ui-tabs-tab ui-corner-top ui-state-default ui-tab" aria-controls="google_oauth" aria-labelledby="ui-id-2" :class="{'ui-tabs-active ui-state-active': currentTab == 2}"><a @click.stop.prevent="currentTab = 2" role="presentation" tabindex="-1" class="ui-tabs-anchor" id="ui-id-2">Google OAuth</a></li>
              <li role="tab" tabindex="-2" class="ui-tabs-tab ui-corner-top ui-state-default ui-tab" aria-controls="google_recaptcha" aria-labelledby="ui-id-3" :class="{'ui-tabs-active ui-state-active': currentTab == 3}"><a @click.stop.prevent="currentTab = 3" role="presentation" tabindex="-1" class="ui-tabs-anchor" id="ui-id-1">Google Recaptcha</a></li>
              <li role="tab" tabindex="-3" class="ui-tabs-tab ui-corner-top ui-state-default ui-tab" aria-controls="beta" aria-labelledby="ui-id-4" :class="{'ui-tabs-active ui-state-active': currentTab == 4}"><a @click.stop.prevent="currentTab = 4" role="presentation" tabindex="-1" class="ui-tabs-anchor" id="ui-id-1">Beta</a></li>
              <li role="tab" tabindex="-4" class="ui-tabs-tab ui-corner-top ui-state-default ui-tab" aria-controls="headerLink" aria-labelledby="ui-id-5" :class="{'ui-tabs-active ui-state-active': currentTab == 5}"><a @click.stop.prevent="currentTab = 5" role="presentation" tabindex="-1" class="ui-tabs-anchor" id="ui-id-5">Header</a></li>
              <li role="tab" tabindex="-5" class="ui-tabs-tab ui-corner-top ui-state-default ui-tab" aria-controls="password_lockout_time" aria-labelledby="ui-id-6" :class="{'ui-tabs-active ui-state-active': currentTab == 6}"><a @click.stop.prevent="currentTab = 6" role="presentation" tabindex="-1" class="ui-tabs-anchor" id="ui-id-6">Password Lockout Time</a></li>
            </ul>
            <div class="tab-content">
              <div id="office365" aria-labelledby="ui-id-1" role="tabpanel" class="ui-tabs-panel ui-corner-bottom ui-widget-content" aria-hidden="false" v-show="currentTab === 1">
                <fieldset class="inputs"><legend><span>Office 365</span></legend>
                  <ol>
                    <li class="string input required stringish" id="office365_key_input"><label class="label">Office 365 key<abbr title="required">*</abbr></label><input :readOnly="!isEditing" id="office365_key" v-model="settings.office365_key" type="text"></li>
                    <li class="string input required stringish" id="office365_secret_input"><label class="label">Office 365 secret<abbr title="required">*</abbr></label><input :readOnly="!isEditing" id="office365_secret" v-model="settings.office365_secret" :type="textType"></li>
                  </ol>
                </fieldset>
              </div>
              <div id="google_oauth" aria-labelledby="ui-id-2" role="tabpanel" class="ui-tabs-panel ui-corner-bottom ui-widget-content" aria-hidden="true" v-show="currentTab === 2">
                <fieldset class="inputs"><legend><span>Google OAuth</span></legend>
                  <ol>
                    <li class="string input required stringish" id="google_oauth_key_input"><label class="label">Google oauth key<abbr title="required">*</abbr></label><input :readOnly="!isEditing" id="google_oauth_key" v-model="settings.google_oauth_key" type="text"></li>
                    <li class="string input required stringish" id="google_oauth_secret_input"><label class="label">Google oauth secret<abbr title="required">*</abbr></label><input :readOnly="!isEditing" id="google_oauth_secret" v-model="settings.google_oauth_secret" :type="textType"></li>
                  </ol>
                </fieldset>
              </div>
              <div id="google_recaptcha" aria-labelledby="ui-id-3" role="tabpanel" class="ui-tabs-panel ui-corner-bottom ui-widget-content" aria-hidden="true" v-show="currentTab === 3">
                <fieldset class="inputs"><legend><span>Google Recaptcha</span></legend>
                  <ol>
                    <li class="string input required stringish" id=""><label class="label">Host URL<abbr title="required">*</abbr></label><input :readOnly="!isEditing" id="" v-model="settings.host_url" type="text"></li>
                    <li class="string input required stringish" id=""><label class="label">Google recaptcha key<abbr title="required">*</abbr></label><input :readOnly="!isEditing" id="" v-model="settings.google_recaptcha_site_key" :type="textType"></li>
                  </ol>
                </fieldset>
              </div>
              <div id="beta" aria-labelledby="ui-id-4" role="tabpanel" class="ui-tabs-panel ui-corner-bottom ui-widget-content" aria-hidden="true" v-show="currentTab === 4">
                <fieldset class="inputs"><legend><span>Beta Status</span></legend>
                  <ol>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        Beta Status <abbr title="required">*</abbr>
                      </label>
                      <input :disabled="!isEditing" id="" v-model="settings.beta_status" type="checkbox">
                    </li>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        Beta Disclaimer url <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.beta_url" type="text">
                    </li>
                  </ol>
                </fieldset>
              </div>
              <div id="headerLink" aria-labelledby="ui-id-5" role="tabpanel" class="ui-tabs-panel ui-corner-bottom ui-widget-content" aria-hidden="true" v-show="currentTab === 5">
                <fieldset class="inputs"><legend><span>Header</span></legend>
                  <ol>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        Help URL <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.public_url" type="text">
                    </li>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        Privacy URL <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.privacy_url" type="text">
                    </li>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        About URL <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.about_url" type="text">
                    </li>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        Terms URL <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.terms_url" type="text">
                    </li>
                  </ol>
                </fieldset>
              </div>
              <div id="password_lockout_time" aria-labelledby="ui-id-6" role="tabpanel" class="ui-tabs-panel ui-corner-bottom ui-widget-content" aria-hidden="true" v-show="currentTab === 6">
                <fieldset class="inputs"><legend><span>Password Lockout Time</span></legend>
                  <ol>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        Failed Password Attempts <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.failed_password_attempts" type="number">
                    </li>
                    <li class="string input required stringish" id="">
                      <label class="label">
                         Lockout Period (mins only) <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.lockout_period" type="number">
                    </li>
                    <li class="string input required stringish" id="">
                      <label class="label">
                        Permanent Lock File after Attempts <abbr title="required">*</abbr>
                      </label>
                      <input :readOnly="!isEditing" id="" v-model="settings.permanent_lock" type="number">
                    </li>
                  </ol>
                </fieldset>
              </div>
            </div>
          </div>
          <fieldset class="actions" v-if="isEditing">
            <ol>
              <li class="action input_action " id="submit_settings"><input :readOnly="!isEditing" type="submit"></li>
            </ol>
          </fieldset>
        </form>
      </div>`
    });
  }

});
