import mongoose from 'mongoose';

const CategorySchema = new mongoose.Schema({
  _id: {
    type: String, // ID từ API nguồn (ví dụ: "252e74b4c832ddb4233d7499f5ed122e")
    required: true
  },
  name: {
    type: String,
    required: true
  },
  slug: {
    type: String,
    required: true,
    unique: true
  }
}, {
  timestamps: true 
});

const Category = mongoose.model('Category', CategorySchema);
export default Category;
