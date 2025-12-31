import express from 'express';
import { createMovie, deleteMovie, getAllMovies, getMovieBySlug, updateMovie } from '../controllers/Movie.controller.js';

const router = express.Router();

router.get('/', getAllMovies);
router.get('/:slug', getMovieBySlug);
router.post('/', createMovie); // Add auth middleware if needed
router.put('/:id', updateMovie); // Add auth middleware if needed
router.delete('/:id', deleteMovie); // Add auth middleware if needed

export default router;
