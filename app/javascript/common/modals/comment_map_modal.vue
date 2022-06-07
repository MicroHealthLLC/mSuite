<template>
  <div class="">
    <sweet-modal ref="commentBoxModal" class="of_v bg-color" title="Comments">
      <div class="comments-container comment_model">
        <ul id="comments-list" class="comments-list" v-for="comment in reverseComments" v-if="myComments">
          <li>
            <div class="comment-main-level"> 
              <div class="comment-box"> 
                <div class="row comment-content">
                  <div class="col-10">
                    <input
                      type="input"
                      v-model="comment.message"
                      class="form__field"
                      placeholder="Type Your Comment Here..."
                      @keydown.enter="updateComment(comment, comment)"
                      v-if="editCommentField && comment.id == selectedComment.id"
                      required />
                    <span v-else>
                      {{ comment.message }}
                    </span>
                  </div>
                  <div class="col-1">
                    <b-dropdown 
                      variant="link"
                      toggle-class="text-decoration-none text-muted" no-caret >
                      <template #button-content>
                        <div v-if="comment.feedback || comment.status">
                          <span v-if="comment.feedback === 'thumbsUp' && !comment.status" class="feedback feedback-thumbup"> 👍 </span>
                          <span v-if="comment.feedback === 'thumbsDown'" class="mt-1 feedback feedback-thumbdown"> 👎 </span>
                          <span v-if="comment.status" class="feedback feedback-check"> ✅ </span>
                        </div>
                        <i class="fas fa-smile-plus" v-else></i> <span class="sr-only">Add feedback</span>
                      </template>
                      <div class="d-flex justify-content-center feedback-emoji">
                        <div class="px-1">
                          <b-dropdown-item
                            @click="updateComment(comment, '', comment.status = !comment.status)" :class="comment.status ? 'feedback-active':''">
                            ✅
                          </b-dropdown-item>
                        </div>
                        <div class="px-1">
                          <b-dropdown-item 
                            @click="updateComment(comment, 'thumbsUp', false)" :class="comment.feedback === 'thumbsUp'&& !comment.status ? 'feedback-active':''"> 
                            👍 
                          </b-dropdown-item>
                        </div>
                        <div class="px-1">
                          <b-dropdown-item 
                            @click="updateComment(comment, 'thumbsDown', false)" :class="comment.feedback === 'thumbsDown' ? 'feedback-active':''"> 
                            👎
                          </b-dropdown-item>
                        </div>
                      </div>
                    </b-dropdown>
                    </div><div class="col-1">
                    <b-dropdown 
                      variant="link"
                      id="dropdown-left" 
                      toggle-class="text-decoration-none text-muted" no-caret
                      class="feedback feedback-button">
                      <template #button-content>
                        <i class="fas fa-ellipsis-h-alt"></i> <span class="sr-only">...</span>
                      </template>
                      <b-dropdown-item
                        class="pl-3"
                        @click="toggleReply(comment)">
                        Reply
                      </b-dropdown-item>
                      <b-dropdown-item
                        class="pl-3"
                        @click="toggleDelete(comment)">
                        Remove
                      </b-dropdown-item>
                      <b-dropdown-item
                        class="pl-3"
                        @click="EditComment(comment)">
                        Edit
                      </b-dropdown-item>
                    </b-dropdown>
                  </div>
                </div>
              </div>
            </div> 
            <ul class="comments-list reply-list" v-if="comment.children">
              <li v-for="child in comment.children"> 
                <div class="comment-box"> 
                  <div class="comment-content">
                    {{ child.message }}
                  </div>
                </div>
              </li> 
              <div v-if="replyField && selectedComment.id === comment.id">
                  <div class="row mb-2">
                    <div class="form__group field">
                      <input 
                        type="input" 
                        v-model="replyNotes" 
                        class="form__field" 
                        placeholder="Type Your Reply Here..." 
                        @keydown.enter="postReplyComment(comment)"
                        required />
                      <label for="name" class="form__label">Your Reply</label>
                    </div>
                    <i class="fas fa-times feedback feedback-cancel mt-4" @click="replyField = false"></i>
                  </div>
                </div>
            </ul>
          </li>
        </ul>
      </div>
      <div class="">
        <div class="form__group__parent field">
          <input 
            type="input" 
            v-model="nodeNotes" 
            class="form__field" 
            placeholder="Type Your Comment Here..." 
            @keydown.enter="postComment"
            required />
          <label for="name" class="form__label">Comment Me!</label>
        </div>
      </div>
    </sweet-modal>
    <sweet-modal ref="deleteCommentConfirm" class="of_v" icon="warning" title="Delete Comment">
      Do you want to delete this comment?
      <button slot="button" @click="deleteComment(commentObj)" class="btn btn-warning mr-2">Delete</button>
      <button slot="button" @click="$refs['deleteCommentConfirm'].close()" class="btn btn-secondary">Cancel</button>
    </sweet-modal>
  </div>
</template>
<script>
  import http from "../http"

  export default {
    name: 'commentBoxModal',
    props: ['MindMap'],
    data () {
      return {
        nodeNotes: '',
        replyNotes:'',
        comments: [],
        myComments: [],
        commentObj: {},
        selectedComment: {id: null},
        replyField: false,
        editCommentField: false
      }
    },
    components: {},
    channels: {
      WebCommentsChannel: {
        connected() {},
        rejected() {},
        received(data) {
          if (data.message === "Comment Created" || data.message === "Comment Updated" || data.message === "Comment Deleted") {
            this.getComments()
            this.renderComments()
          }
        },
        disconnected() {}
      }
    },
    mounted(){
      this.$cable.subscribe({
        channel: "WebCommentsChannel",
        room: this.MindMap.id,
      });
      this.getComments()
    },
    computed: {
      reverseComments() {
        return this.myComments.slice().reverse();
      }     
    },
    methods:{
      getComments () {
        http.get(`/comments.json?mindmap_id=${this.MindMap.id}`).then((res) => {
          this.comments = res.data.comments
          this.renderComments()
        }).catch(err => {
          console.log(err)
        })
      },
      postComment () {
        let data = { message: this.nodeNotes, mindmap_id: this.MindMap.id}
        http.post(`/comments.json`, data).then((res) => {
          this.nodeNotes = ''
          this.renderComments()
        }).catch(err => {
          console.log(err)
        })
      },
      postReplyComment (comment) {
        let parent_comment = comment.id
        let data = { message: this.replyNotes, mindmap_id: this.MindMap.id, parent_comment: comment.id }
        http.post(`/comments.json`, data).then((res) => {
          this.replyNotes = ''
          this.replyField = false
          this.renderComments()
        }).catch(err => {
          console.log(err)
        })
      },
      updateComment (comment, feedback, status) {
        if(comment.feedback != '' && comment.feedback === feedback) feedback = ''
        let data = { comment: {
          id: comment.id,
          message: comment.message,
          feedback: feedback,
          status: status,
        }}

        http.patch(`/comments/${comment.id}.json`, data).then((res) => {
          this.editCommentField = false
        }).catch(err => {
          console.log(err)
        })
      },
      toggleDelete(comment){
        this.commentObj = comment
        this.$refs['deleteCommentConfirm'].open()
      },
      EditComment(commentObj) {
        this.selectedComment = commentObj
        this.editCommentField = true
      },
      deleteComment (comment) {
        http.delete(`/comments/${comment.id}.json`);
        this.renderComments()
        this.$refs['deleteCommentConfirm'].close()
      },
      toggleReply (comment) {
        this.selectedComment = comment
        this.replyField = true
      },
      renderComments(){
        let parent_comments = []
        this.comments.forEach((comment) => {
          if(comment.parent_comment == null){
            parent_comments.push(comment)
          }
        })
        parent_comments = parent_comments.map((comment, index) => {
          return {
            id: comment.id,
            message: comment.message,
            status: comment.status,
            feedback: comment.feedback,
            children: []
          }
        })
        this.getChildComment(parent_comments)
      },
      getChildComment(parent_comments){
        let childComments = []
        this.comments.forEach((comment) => {
          parent_comments.forEach((p, index)=> {
            if(p.id == comment.parent_comment){
              let obj = { message: comment.message, 
                          id: comment.id, 
                          parent_comment: p.id, 
                          children: []}
              parent_comments[index].children.push(obj)
            }
          })
        })
        if(childComments.length > 0){
          this.getChildComment(_.uniq(childComments))
        }
        this.myComments = parent_comments
      },
    }
  }
</script>
<style lang="scss">
  .bg-color{
    background: #efefef;
  }
  .comment_model{
    max-height: 70vh;
    overflow: scroll;
  }
  .active{
    opacity: 0.7;
    border-radius: 50%;
  }
  .feedback{
    cursor: pointer;
    font-size: 15px;
    border: none !important;
    color: grey;
    &-button{
      display: flex;
      align-items: center;
      justify-content: center;
      color: #aaaaaa;
      &:hover{
        background:none !important;
        color: grey;
      }
    }
    &-emoji{
      min-width: 6rem !important;
    }
    &-cancel{
      color: red;
    }
    &-active{
      padding-left: 5px;
      padding-right: 5px;
      background: #647898;
      border-radius: 10px;
    }
    &:hover{
        background: none !important;
      }
  }

  $primary: #AB9AFD;
  $secondary: #3F96FF;
  $gray: #9b9b9b;
  .form__group {
    position: relative;
    padding: 15px 0 0;
    margin-top: -5px;
    margin-left: 0;
    width: 50%;
  }
  .form__group__parent {
    position: relative;
    padding: 15px 0 0;
    margin-top: 10px;
    width: 100%;
  }
  .form__field {
    width: 100%;
    border: 0;
    border-bottom: 2px solid $gray;
    outline: 0;
    font-size: 15px;
    padding: 7px 0;
    background: transparent;
    transition: border-color 0.2s;

    &::placeholder {
      color: transparent;
    }

    &:placeholder-shown ~ .form__label {
      font-size: 12px;
      cursor: text;
      top: 30px;
    }
  }

  .form__label {
    position: absolute;
    top: 0;
    display: block;
    transition: 0.2s;
    font-size: 1rem;
    color: $gray;
  }

  .form__field:focus {
    ~ .form__label {
      position: absolute;
      top: 0;
      display: block;
      transition: 0.2s;
      font-size: 1rem;
      color: $primary;
      font-weight:700;    
    }
    padding-bottom: 6px;  
    font-weight: 700;
    border-width: 3px;
    border-image: linear-gradient(to right, $primary,$secondary);
    border-image-slice: 1;
  }
  /* reset input */
  .form__field{
    &:required,&:invalid { box-shadow:none; }
  }
  .btn-outline-primary {
    color: #aaaaaa;
    border: none !important;
    &:hover, &:focus, &:active{
      background: none !important;
      color: grey;
    }
  }
  .show > .btn-outline-primary.dropdown-toggle {
    color: grey;
    background: none !important;
    border: none !important;
  }
  .dropdown-item{
    padding: 0 !important;
  }
  .dropdown-menu{
    min-width: 5rem !important;
  }
  .dropdown-menu.show {
    background: #eeeeee !important;
  }
  .dropdown-item.active, .dropdown-item:active, .dropdown-item:hover, .dropdown-item:focus {
    color: black;
    text-decoration: none;
    background: none !important;
  }
  .comments-container {
    width: 100%;
  }
.comments-list {
	position: relative;
}
/**
 * Lineas / Detalles
 -----------------------*/
.comments-list:before {
	content: '';
	width: 2px;
	height: 94%;
	background: #c7cacb;
	position: absolute;
	left: 0;
	top: 6%;
}
.comments-list:after {
	content: '';
	position: absolute;
	background: #c7cacb;
	bottom: -1%;
	left: -0.2%;
	width: 6px;
	height: 6px;
	border: 3px solid #dee1e3;
	-webkit-border-radius: 50%;
	-moz-border-radius: 50%;
	border-radius: 50%;
}
.reply-list:before, .reply-list:after {display: none;}
.reply-list li:before {
	content: '';
	width: 15%;
	height: 2px;
	background: #c7cacb;
	position: absolute;
	top: 40%;
	left: -22.1%;
}
.comments-list li {
	margin-bottom: 15px;
	display: block;
	position: relative;
}
.comments-list li:after {
	content: '';
	display: block;
	clear: both;
	height: 0;
	width: 0;
}
.reply-list {
	padding-left: 12.2%;
	clear: both;
}
/**
 * Caja del Comentario
 ---------------------------*/
.comments-list .comment-box {
  margin-top: 2%;
  margin-right: 5%;
  width: 100%;
	float: right;
	position: relative;
  margin-bottom: 2%;
	-webkit-box-shadow: 0 1px 1px rgba(0,0,0,0.15);
	-moz-box-shadow: 0 1px 1px rgba(0,0,0,0.15);
	box-shadow: 0 1px 1px rgba(0,0,0,0.15);
}
.comments-list .comment-box:before {
	border-width: 11px 13px 11px 0;
	border-color: transparent rgba(0,0,0,0.05);
	left: -12px;
}
.reply-list .comment-box {
	width: 100%;
}
.comment-box .comment-head {
	background: #FCFCFC;
	padding: 10px 12px;
	border-bottom: 1px solid #E5E5E5;
	overflow: hidden;
	-webkit-border-radius: 4px 4px 0 0;
	-moz-border-radius: 4px 4px 0 0;
	border-radius: 4px 4px 0 0;
}
.comment-box .comment-head i {
	float: right;
	margin-left: 14px;
	position: relative;
	top: 2px;
	color: #A6A6A6;
	cursor: pointer;
	-webkit-transition: color 0.3s ease;
	-o-transition: color 0.3s ease;
	transition: color 0.3s ease;
}
.comment-box .comment-head i:hover {
	color: #03658c;
}
.comment-box .comment-name {
	color: #283035;
	font-size: 14px;
	font-weight: 700;
	float: left;
	margin-right: 10px;
}
.comment-box .comment-name a {
	color: #283035;
}
.comment-box .comment-head span {
	float: left;
	color: #999;
	font-size: 13px;
	position: relative;
	top: 1px;
}
.comment-box .comment-content {
	background: #FFF;
	padding: 12px;
	font-size: 15px;
	color: #595959;
  background: #efefef;
	-webkit-border-radius: 0 0 4px 4px;
	-moz-border-radius: 0 0 4px 4px;
	border-radius: 0 0 4px 4px;
}
.comment-box .comment-name.by-author, .comment-box .comment-name.by-author a {color: #03658c;}
.comment-box .comment-name.by-author:after {
	content: 'autor';
	background: #03658c;
	color: #FFF;
	font-size: 12px;
	padding: 3px 5px;
	font-weight: 700;
	margin-left: 10px;
	-webkit-border-radius: 3px;
	-moz-border-radius: 3px;
	border-radius: 3px;
}
/** =====================
 * Responsive
 ========================*/
@media only screen and (max-width: 766px) {
	.comments-container {
		width: 480px;
	}
	.comments-list .comment-box {
		width: 390px;
	}
	.reply-list .comment-box {
		width: 320px;
	}
}
</style>
