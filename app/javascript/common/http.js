import axios from 'axios'

export default axios.create({
  headers: {
    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes['content'].value,
    'X-Key-Inflection': 'camel'
  }
})
